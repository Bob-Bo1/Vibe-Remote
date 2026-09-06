"""Read the paired RC003 HID collection directly for diagnosis.

This is a passive probe. It does not inject keys and does not change the
device or Windows security configuration. It exists to determine whether the
HID collection can be read without the optional WUDFHost injection path.
"""

from __future__ import annotations

import argparse
import ctypes
import time
from ctypes import wintypes

from ovb_rc003 import hid_identity, raw_input_windows


GENERIC_READ = 0x80000000
FILE_SHARE_READ = 0x00000001
FILE_SHARE_WRITE = 0x00000002
OPEN_EXISTING = 3
FILE_FLAG_OVERLAPPED = 0x40000000
ERROR_IO_PENDING = 997
WAIT_OBJECT_0 = 0
WAIT_TIMEOUT = 258
INFINITE = 0xFFFFFFFF
INVALID_HANDLE_VALUE = ctypes.c_void_p(-1).value


class OVERLAPPED(ctypes.Structure):
    _fields_ = [
        ("Internal", ctypes.c_size_t),
        ("InternalHigh", ctypes.c_size_t),
        ("Offset", wintypes.DWORD),
        ("OffsetHigh", wintypes.DWORD),
        ("hEvent", wintypes.HANDLE),
    ]


def _configure_api():
    kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)
    kernel32.CreateFileW.argtypes = (
        wintypes.LPCWSTR,
        wintypes.DWORD,
        wintypes.DWORD,
        wintypes.LPVOID,
        wintypes.DWORD,
        wintypes.DWORD,
        wintypes.HANDLE,
    )
    kernel32.CreateFileW.restype = wintypes.HANDLE
    kernel32.CreateEventW.argtypes = (
        wintypes.LPVOID,
        wintypes.BOOL,
        wintypes.BOOL,
        wintypes.LPCWSTR,
    )
    kernel32.CreateEventW.restype = wintypes.HANDLE
    kernel32.ResetEvent.argtypes = (wintypes.HANDLE,)
    kernel32.ResetEvent.restype = wintypes.BOOL
    kernel32.ReadFile.argtypes = (
        wintypes.HANDLE,
        wintypes.LPVOID,
        wintypes.DWORD,
        ctypes.POINTER(wintypes.DWORD),
        ctypes.POINTER(OVERLAPPED),
    )
    kernel32.ReadFile.restype = wintypes.BOOL
    kernel32.GetOverlappedResult.argtypes = (
        wintypes.HANDLE,
        ctypes.POINTER(OVERLAPPED),
        ctypes.POINTER(wintypes.DWORD),
        wintypes.BOOL,
    )
    kernel32.GetOverlappedResult.restype = wintypes.BOOL
    kernel32.CancelIoEx.argtypes = (
        wintypes.HANDLE,
        ctypes.POINTER(OVERLAPPED),
    )
    kernel32.CancelIoEx.restype = wintypes.BOOL
    kernel32.WaitForSingleObject.argtypes = (wintypes.HANDLE, wintypes.DWORD)
    kernel32.WaitForSingleObject.restype = wintypes.DWORD
    kernel32.CloseHandle.argtypes = (wintypes.HANDLE,)
    kernel32.CloseHandle.restype = wintypes.BOOL
    return kernel32


def _read_one(kernel32, handle, report_length: int, timeout_ms: int):
    event = kernel32.CreateEventW(None, True, False, None)
    if not event:
        raise ctypes.WinError(ctypes.get_last_error())
    overlapped = OVERLAPPED(hEvent=event)
    buffer = ctypes.create_string_buffer(report_length)
    bytes_read = wintypes.DWORD(0)
    try:
        started = kernel32.ReadFile(
            handle,
            buffer,
            report_length,
            ctypes.byref(bytes_read),
            ctypes.byref(overlapped),
        )
        if not started:
            error = ctypes.get_last_error()
            if error != ERROR_IO_PENDING:
                raise ctypes.WinError(error)
        result = kernel32.WaitForSingleObject(event, timeout_ms)
        if result == WAIT_TIMEOUT:
            kernel32.CancelIoEx(handle, ctypes.byref(overlapped))
            kernel32.WaitForSingleObject(event, 1000)
            return None
        if result != WAIT_OBJECT_0:
            raise ctypes.WinError(ctypes.get_last_error())
        if not kernel32.GetOverlappedResult(
            handle, ctypes.byref(overlapped), ctypes.byref(bytes_read), False
        ):
            raise ctypes.WinError(ctypes.get_last_error())
        return bytes(buffer.raw[: bytes_read.value])
    finally:
        kernel32.CloseHandle(event)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--seconds", type=float, default=90.0)
    args = parser.parse_args()

    paths = raw_input_windows.enumerate_matching_device_paths()
    path = hid_identity.select_single_device_path(paths)
    kernel32 = _configure_api()
    handle = kernel32.CreateFileW(
        path,
        GENERIC_READ,
        FILE_SHARE_READ | FILE_SHARE_WRITE,
        None,
        OPEN_EXISTING,
        FILE_FLAG_OVERLAPPED,
        None,
    )
    if handle in (None, 0, INVALID_HANDLE_VALUE):
        raise ctypes.WinError(ctypes.get_last_error())

    print(f"READY path={path}", flush=True)
    print("请依次按：返回、音量+、音量-、左方向键；每次按下后松开。", flush=True)
    deadline = time.monotonic() + max(1.0, args.seconds)
    count = 0
    try:
        while time.monotonic() < deadline:
            timeout_ms = max(1, min(1000, int((deadline - time.monotonic()) * 1000)))
            report = _read_one(kernel32, handle, 64, timeout_ms)
            if report is None:
                continue
            count += 1
            try:
                usages = sorted(hid_identity.decode_report_usages(report))
            except ValueError as exc:
                usages = f"decode_error={exc}"
            print(f"REPORT {count}: {report.hex()} usages={usages}", flush=True)
    finally:
        kernel32.CloseHandle(handle)
    print(f"SUMMARY reports={count}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

"""Runs the RC003 bridge inside the settings application's process.

The packaged GUI used to start a second ``RemoteMicRC003.exe --bridge``
process.  That remains available through the legacy launcher, but the
packaged settings window now owns one bridge runtime in a background thread.
The runtime keeps the asyncio/WinRT work away from Qt's GUI thread while the
user still has one visible application and one executable to operate.

This module deliberately imports the concrete bridge application lazily.  A
settings window can therefore be imported, tested, or opened on a machine
without the optional WinRT packages before the user actually starts RC003.
"""

from __future__ import annotations

import asyncio
import logging
import threading
from typing import Callable, Optional


STATUS_STARTING = "starting"
STATUS_RUNNING = "running"
STATUS_STOPPED = "stopped"
STATUS_ALREADY_RUNNING = "already_running"
STATUS_UNAVAILABLE = "unavailable"
STATUS_FAILED = "failed"
STATUS_DEVICE_CONNECTING = "device_connecting"
STATUS_DEVICE_CONNECTED = "device_connected"
STATUS_DEVICE_DISCONNECTED = "device_disconnected"

StatusCallback = Callable[[str], None]


class IntegratedBridgeRuntime:
    """Owns one in-process RC003 bridge loop.

    ``start()`` and ``stop()`` are safe to call from the Qt GUI thread.  The
    bridge itself runs on a dedicated thread with its own asyncio loop, which
    is required because Qt's event loop must remain responsive for the
    settings window.  The Win32 named mutex is acquired and released on that
    same bridge thread because mutex ownership is thread-bound on Windows.
    """

    def __init__(self, on_status: Optional[StatusCallback] = None) -> None:
        self._on_status = on_status or (lambda _status: None)
        self._lock = threading.RLock()
        self._thread: Optional[threading.Thread] = None
        self._loop: Optional[asyncio.AbstractEventLoop] = None
        self._bridge_app = None
        self._run_task: Optional[asyncio.Task] = None
        self._stop_requested = threading.Event()
        self._logger = logging.getLogger("ovb_rc003.integrated_bridge")

    @property
    def is_running(self) -> bool:
        with self._lock:
            return bool(self._thread and self._thread.is_alive())

    def start(self) -> bool:
        """Starts the integrated bridge, returning ``False`` if it could
        not stop a previous runtime cleanly.
        """

        if not self.stop():
            self._emit(STATUS_FAILED)
            return False

        with self._lock:
            self._stop_requested.clear()
            thread = threading.Thread(
                target=self._thread_main,
                name="RemoteMicRC003-bridge",
                daemon=True,
            )
            self._thread = thread
        self._emit(STATUS_STARTING)
        thread.start()
        return True

    def stop(self, timeout: float = 8.0) -> bool:
        """Requests bridge shutdown and waits a bounded time for cleanup."""

        self._stop_requested.set()
        with self._lock:
            thread = self._thread
            loop = self._loop
            bridge_app = self._bridge_app
            run_task = self._run_task

        if loop is not None and run_task is not None and not loop.is_closed():
            # Cancelling the supervisor task also interrupts a retry sleep.
            # Calling RC003App.stop() alone wakes a connected wait, but a
            # failed connection can otherwise be sleeping for up to the
            # configured backoff period.
            try:
                loop.call_soon_threadsafe(run_task.cancel)
            except (RuntimeError, OSError):
                pass
        elif loop is not None and bridge_app is not None and not loop.is_closed():
            try:
                asyncio.run_coroutine_threadsafe(bridge_app.stop(), loop)
            except (RuntimeError, OSError):
                # The bridge thread may be between loop creation and startup,
                # or it may already be closing.  The event checked by the
                # thread itself still prevents a late start.
                pass

        if thread is None or thread is threading.current_thread():
            return True
        thread.join(timeout=max(0.0, timeout))
        return not thread.is_alive()

    def _emit(self, status: str) -> None:
        try:
            self._on_status(status)
        except Exception:  # noqa: BLE001 - status reporting must not kill bridge
            self._logger.exception("integrated bridge status callback failed")

    def _thread_main(self) -> None:
        # Imports are intentionally inside the worker.  This keeps importing
        # the settings package independent of WinRT availability.
        from . import app, single_instance

        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        with self._lock:
            self._loop = loop

        try:
            if self._stop_requested.is_set():
                return

            # The guard is held on this exact thread for its entire lifetime;
            # ReleaseMutex must be called by the owner thread on Windows.
            with single_instance.BridgeInstanceGuard():
                bridge_app = app.RC003App(on_status=self._emit)
                with self._lock:
                    self._bridge_app = bridge_app
                if self._stop_requested.is_set():
                    loop.run_until_complete(bridge_app.stop())
                    return

                self._emit(STATUS_RUNNING)

                async def run_bridge() -> None:
                    try:
                        await bridge_app.run_forever()
                    except asyncio.CancelledError:
                        # ``stop()`` cancels this task so an in-progress
                        # reconnect backoff cannot hold the GUI shutdown.
                        pass
                    finally:
                        await bridge_app.stop()

                run_task = loop.create_task(run_bridge())
                with self._lock:
                    self._run_task = run_task
                loop.run_until_complete(run_task)
                self._emit(STATUS_STOPPED)
        except single_instance.DuplicateInstanceError:
            self._emit(STATUS_ALREADY_RUNNING)
        except single_instance.SingleInstanceUnavailableError:
            self._emit(STATUS_UNAVAILABLE)
        except single_instance.MutexCleanupError:
            self._logger.exception("integrated bridge mutex cleanup failed")
            self._emit(STATUS_FAILED)
        except Exception:  # noqa: BLE001 - surface through the settings status
            self._logger.exception("integrated bridge stopped unexpectedly")
            self._emit(STATUS_FAILED)
        finally:
            with self._lock:
                self._bridge_app = None
                self._run_task = None
                self._loop = None
                if self._thread is threading.current_thread():
                    self._thread = None
            try:
                loop.run_until_complete(loop.shutdown_asyncgens())
            except Exception:  # noqa: BLE001 - loop is already being retired
                pass
            loop.close()
            asyncio.set_event_loop(None)

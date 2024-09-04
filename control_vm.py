from __future__ import annotations
import os
import sys
from typing import Any
from google.api_core.extended_operation import ExtendedOperation
from google.cloud import compute_v1
import functions_framework
import concurrent.futures

def wait_for_extended_operation(
    operation: ExtendedOperation, verbose_name: str = "operation", timeout: int = 300
) -> Any:
    """
    Waits for the extended (long-running) operation to complete.
    If the operation is successful, it will return its result.
    If the operation ends with an error, an exception will be raised.
    If there were any warnings during the execution of the operation
    they will be printed to sys.stderr.
    
    Args:
        operation: a long-running operation you want to wait on.
        verbose_name: (optional) a more verbose name of the operation,
            used only during error and warning reporting.
        timeout: how long (in seconds) to wait for operation to finish.
            If None, wait indefinitely.
    
    Returns:
        Whatever the operation.result() returns.
    
    Raises:
        This method will raise the exception received from `operation.exception()`
        or RuntimeError if there is no exception set, but there is an `error_code`
        set for the `operation`.

        In case of an operation taking longer than `timeout` seconds to complete,
        a `concurrent.futures.TimeoutError` will be raised.
    """
    try:
        result = operation.result(timeout=timeout)
    except concurrent.futures.TimeoutError:
        print(f"Operation timed out after {timeout} seconds.", file=sys.stderr, flush=True)
        raise
    if operation.error_code:
        print(
            f"Error during {verbose_name}: [Code: {operation.error_code}]: {operation.error_message}",
            file=sys.stderr,
            flush=True,
        )
        print(f"Operation ID: {operation.name}", file=sys.stderr, flush=True)
        raise operation.exception() or RuntimeError(operation.error_message)
    if operation.warnings:
        print(f"Warnings during {verbose_name}:\n", file=sys.stderr, flush=True)
        for warning in operation.warnings:
            print(f" - {warning.code}: {warning.message}", file=sys.stderr, flush=True)
    return result

def manage_instance(action: str) -> str:
    """
    Starts or stops a Google Compute Engine instance using environment variables.
    
    Args:
        action: Either 'start' or 'stop'.
    
    Returns:
        A string indicating the result of the operation.
    """
    project_id = os.environ.get('PROJECT_ID')
    zone = os.environ.get('ZONE')
    instance_name = os.environ.get('INSTANCE_NAME')

    if not all([project_id, zone, instance_name]):
        raise ValueError("Environment variables PROJECT_ID, ZONE, and INSTANCE_NAME must be set.")

    instance_client = compute_v1.InstancesClient()

    if action == 'start':
        operation = instance_client.start(
            project=project_id, zone=zone, instance=instance_name
        )
        wait_for_extended_operation(operation, "instance starting")
        return f"Instance {instance_name} started successfully."
    elif action == 'stop':
        operation = instance_client.stop(
            project=project_id, zone=zone, instance=instance_name
        )
        wait_for_extended_operation(operation, "instance stopping")
        return f"Instance {instance_name} stopped successfully."
    else:
        return f"Invalid action: {action}. Use 'start' or 'stop'."

@functions_framework.http
def control_vm(request) -> tuple[str, int]:
    """
    HTTP Cloud Function to manage a Compute Engine instance.
    
    Args:
        request (flask.Request): The request object.
    
    Returns:
        The response text, or any set of values that can be turned into a
        Response object using `make_response`
    """
    action = request.args.get('action')
    if not action:
        return "Please specify an action (start or stop) in the query string.", 400

    try:
        result = manage_instance(action)
        return result, 200
    except ValueError as ve:
        return f"Invalid input: {str(ve)}", 400
    except Exception as e:
        return f"An error occurred: {str(e)}", 500

# Incident 01: App container crashed on startup

## Summary
After the first `terraform apply` of the ECS and ALB stack, the ECS service never reached a running state. The container started and stopped repeatedly.

## Symptoms
- ECS service: desired 1, running 0, pending 1
- ALB target state: draining
- Stopped task reason: "Essential container in task exited"

## Investigation
1. ECS service events and the stopped-task reason showed that the container exited by itself. It was not an image pull or permission problem.
2. Reading `app.py` showed a stray closing brace after the `home()` function.
3. `python3 -m py_compile app.py` confirmed: SyntaxError, unmatched brace on line 33.

## Root cause
A syntax error was committed to the backend repository. Gunicorn could not import the application, so the container exited immediately. The image had never been run locally before it was pushed to ECR.

## Fix
- Removed the stray line, verified it with `py_compile`, and pushed the fix to GitHub.
- Built image v2 and ran it locally; a request to `/` returned the expected JSON message.
- Pushed v2 to ECR (tags are immutable, so v1 could not be overwritten) and updated Terraform to use v2.

## Lessons learned
- Always run an image locally before pushing it to the registry.
- Add a syntax check to the CI pipeline before building the image (planned for Phase 5).
- Immutable tags turn every fix into a new version, which keeps deployments traceable.
- Read ECS service events and stopped-task reasons first: they show whether the platform or the app is at fault.
- Use a targeted destroy to stop billing without deleting the ECR images and secrets.

## Open item
Gunicorn logs a permission warning for the non-root user's home directory. The app works, but the cause is not confirmed yet.

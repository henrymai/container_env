# Containerized Environment

This project provides a convenient way to run your entire development and testing environment inside a Docker container. By doing so, you reduce dependencies on your host machine to just Docker (and Git), while leveraging a fully isolated environment that mirrors production-like conditions or complex setups without polluting your host system.

## Key Advantages

- **Minimal Host Requirements:**
  Only Docker (and Git) are needed on your host. Everything else—languages, libraries, tools—are contained within the environment image.

- **Running as Your Own User ID, Not as Root:**
  A major difference from typical `docker run` sessions is that when you enter this container environment, the process inside the container matches your user and group IDs from the host system. In other words, you’re effectively “yourself” inside the container, not `root`.
  This distinction matters because it prevents common file permission headaches. With normal Docker usage, running as `root` inside a container can leave files owned by `root` on your host, forcing tedious permission fixes. Here, because you share the same UID/GID as on the host, any files created or modified inside the container remain associated with your own user. No extra `chown` steps are required afterward, and your development workflow remains smooth and intuitive.

- **No Code Copying Required:**
  Your home directory is automatically mounted into the container at runtime. This means all your projects, tools, and configuration files are immediately available inside the container environment without having to rebuild images or copy code in. You can edit code on your host and run commands in the container seamlessly.

- **Consistent & Reproducible Environments:**
  Every team member can share the same container image, ensuring everyone has identical tooling and dependencies. This drastically reduces “it works on my machine” problems and simplifies onboarding.

- **Integration with Docker-in-Docker (DIND):**
  Integration tests and scripts that need to spin up additional containers or use Docker Compose can do so directly inside this environment, as the Docker socket and binaries are mounted inside. Run `docker` or `docker-compose` just as if you were on the host.

- **GUI and Network Support:**
  On Linux, GUI apps can use your existing X server. On macOS, run XQuartz and `xhost +host.docker.internal` to display GUI applications launched from inside the container.
  Networking also “just works,” though macOS doesn’t support `--net=host`. Instead, use port publishing (e.g., `-p 8080:8080`) to reach services inside the container at `localhost:8080` on your host.

## Getting Started

1. **Build or Obtain an Image:**
   Create a Docker image that contains your required tools and dependencies. Here’s an example `Dockerfile` based on Ubuntu, installing common utilities and tooling at build time so they’re globally accessible to any user:

   ```
   FROM ubuntu:20.04

   ENV DEBIAN_FRONTEND=noninteractive

   # Install common utilities and language runtimes
   RUN apt-get update && apt-get install -y --no-install-recommends \
       git curl wget build-essential python3-pip python3-venv nodejs npm \
       && rm -rf /var/lib/apt/lists/*

   # Install yarn globally and ensure all users can use it
   RUN npm install --global yarn && \
       chmod -R a+rX /usr/local
   ```

   Build this image:
   ```
   docker build -t my_env:latest .
   ```

2. **Run the Environment:**
   Start a shell inside the container environment:
   ```
   IMAGE=my_env:latest ./env.sh bash
   ```

   You’ll be inside the container as your normal user, with your host’s home directory mounted. All your code is immediately accessible without any copying, and you don’t need `sudo` or permission fixes.

3. **Using EXTRA_DOCKER_FLAGS for Ports & Mounts:**
   Need to publish ports or mount additional directories (beyond your home)? Use `EXTRA_DOCKER_FLAGS`:
   ```
   EXTRA_DOCKER_FLAGS='-p 8080:8080' IMAGE=my_env:latest ./env.sh python3 -m http.server 8080
   ```

   Access `http://localhost:8080` on your host to see the server running inside the container environment. Similarly, you can specify `-v /path/on/host:/path/in/container` if you need special additional mounts.

4. **Running GUI Apps on macOS:**
   On macOS, install and run XQuartz, then:
   ```
   xhost +host.docker.internal
   ```

   Now, when you run GUI applications inside the container (e.g., a graphical editor or browser), they’ll appear on your Mac’s display.

5. **Integration Tests with Docker-in-Docker:**
   Since the container environment mounts the host’s Docker socket and includes Docker binaries, you can run:
   ```
   IMAGE=my_env:latest ./env.sh docker run hello-world
   ```

   This triggers another container from within your environment. Useful for integration tests that depend on spinning up other services.

## Permissions Without Pain

A common issue with standard `docker run` approaches is ending up with `root`-owned files on your host after building or testing inside a container. Here, you run as your normal user, so any files created or modified remain properly owned by your user on the host. No need to run `chown` after the fact, and no wrestling with permissions.

## Architecture and GPU Notes

- **Architecture:**
  On Apple Silicon Macs, Docker Desktop pulls ARM-compatible images if available. If not, it uses emulation. Most common images are multi-arch, so this typically just works.

- **GPU Support:**
  On Linux, `--gpus=all` can enable GPU acceleration if configured properly. On macOS, GPU passthrough is not supported by Docker Desktop in the same way.

## Conclusion

This container environment setup provides a developer-friendly, consistent, and permission-aware environment. It reduces host clutter, preserves user ownership of files, and supports integration testing, GUI apps, and flexible port/directory mounting—all while keeping your development experience smooth and frustration-free.

## License

Licensed under the Apache License, Version 2.0. See the [LICENSE](LICENSE) file for details.


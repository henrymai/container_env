# What this is

Easily work inside of a container image environment without having to install or manage dependencies on your host environment.

The only things you'll probably need to install on your host environment are: podman (or docker) and git.
 * Note that if you choose to use docker, you'll have to replace `podman` with `docker` in the script, but all the args would be the same.

Inside the container environment, most things including X11 and networking will just work as if you were running these things straight on your host environment.

# Example Usage

`IMAGE=pytorch_environment:latest ./env.sh bash`

# Add other directories

Edit the script and pass in whatever `-v outside_dir:inside_dir` you want

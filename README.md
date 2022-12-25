# What this is

Easily work inside of a container image environment without having to install or manage dependencies on your host environment.

The only things you'll need to install on your host environment are: docker (or podman) and git.

Inside the container environment, most things including X11 and networking will just work as if you were running these things straight on your host environment.

Notes:
   * This script will probably not work on a Mac if you use Docker Desktop on Mac. However it should work fine if you just use a Linux vm on Mac and have docker installed normally inside the vm.
   * Script will attempt to autodetect if you have podman and use that if you have that installed.
      * docker in docker support of course is not present when using podman (I have not attempted to try implementing the equivalent version for podman yet).


# Example Usage

`IMAGE=pytorch_environment:latest ./env.sh bash`

# Add other directories

Edit the script and pass in whatever `-v outside_dir:inside_dir` you want

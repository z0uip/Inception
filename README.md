*This project has been created as part of the 42 curriculum by fbenech.*

# Inception

## Description

Inception is a system administration project whose goal is to build a small web infrastructure with **Docker** and **Docker Compose**, inside a virtual machine. Every service runs in its own container, built from a custom Dockerfile (no pre-built images are pulled, only the Debian base image).

The stack is made of three services:

| Service | Role | Port |
|---|---|---|
| **NGINX** | Only entry point of the infrastructure, HTTPS only (TLSv1.2 / TLSv1.3) | 443 (published) |
| **WordPress + php-fpm** | The website, PHP processed by php-fpm | 9000 (internal) |
| **MariaDB** | Database used by WordPress | 3306 (internal) |

Two persistent Docker named volumes store the WordPress database and the WordPress website files. Their data lives in `/home/fbenech/data` on the host. All containers share a dedicated Docker network and restart automatically after a crash.

```
Browser --443/TLS--> NGINX --9000--> WordPress (php-fpm) --3306--> MariaDB
                       |                    |                         |
                       +---- wordpress_data volume ----+        mariadb_data volume
```

### Project description and main design choices

- **Base image**: `debian:bookworm`, the penultimate stable Debian release. The `latest` tag is never used, and the built images are tagged `1.0`.
- **One Dockerfile per service** in `srcs/requirements/<service>/`, with its configuration (`conf/`) and startup script (`tools/`).
- **PID 1 handling**: each startup script ends with `exec`, so the real service (`mariadbd`, `php-fpm8.2 -F`, `nginx -g "daemon off;"`) runs as PID 1 in the foreground. No `tail -f`, `sleep infinity` or infinite-loop hack is used.
- **Idempotent initialisation**: MariaDB and WordPress are configured only on first start, so data in the volumes is preserved across restarts.
- **Secrets**: passwords are stored in `secrets/*.txt` and mounted in `/run/secrets/` through Docker secrets. Non-sensitive settings (domain name, database name, usernames) are in `srcs/.env`. Neither is committed to Git.
- **TLS**: NGINX generates a self-signed certificate at first start and only accepts TLSv1.2 and TLSv1.3.
- **WordPress users**: two users are created automatically with WP-CLI, an administrator (whose name does not contain "admin") and an author.

### Comparisons

**Virtual Machines vs Docker**
A virtual machine emulates a full computer with its own kernel and operating system: strong isolation, but heavy (gigabytes) and slow to start. A Docker container is an isolated process sharing the host kernel: lightweight, starts in seconds and is easy to reproduce, but its isolation is weaker. Here, Docker runs inside a VM to combine both.

**Secrets vs Environment Variables**
Environment variables are simple but visible through `docker inspect` and easily leaked in logs or images. Docker secrets are mounted as read-only files in `/run/secrets/` and only reach the services that need them. This project uses `.env` for non-sensitive configuration and secrets for every password.

**Docker Network vs Host Network**
With a Docker (bridge) network, containers get their own isolated network and reach each other by service name (`mariadb`, `wordpress`); only explicitly published ports are exposed. With `network: host`, a container shares the host's network stack, which removes isolation and is forbidden by the subject.

**Docker Volumes vs Bind Mounts**
A named volume is created and managed by Docker, independent of the host's directory layout. A bind mount maps a specific host path directly into the container. This project uses named volumes (as required), configured with `driver_opts` so that their data is stored in `/home/fbenech/data` while remaining named volumes.

## Instructions

### Prerequisites

- A Linux virtual machine (Debian in this project)
- Docker Engine with the Compose plugin, `make` and `git`
- `sudo` rights

### Setup

1. Clone the repository:
   ```bash
   git clone <repository-url> inception && cd inception
   ```
2. Point the domain name to the VM by adding this line to `/etc/hosts`:
   ```
   127.0.0.1   fbenech.42.fr
   ```
3. Create the secrets (one value per file, never commit them):
   ```bash
   mkdir -p secrets
   printf '<db password>\n'      > secrets/db_password.txt
   printf '<db root password>\n' > secrets/db_root_password.txt
   printf '<wp admin password>\n' > secrets/wp_admin_password.txt
   printf '<wp user password>\n'  > secrets/wp_user_password.txt
   ```
4. Create `srcs/.env`:
   ```
   DOMAIN_NAME=fbenech.42.fr
   MYSQL_DATABASE=wordpress
   MYSQL_USER=wpuser
   WP_TITLE=Inception
   WP_ADMIN_USER=<administrator name, without "admin">
   WP_ADMIN_EMAIL=<email>
   WP_USER=<second user name>
   WP_USER_EMAIL=<email>
   ```

### Usage

| Command | Effect |
|---|---|
| `make` | Create the data folders, build the images and start everything |
| `make down` | Stop and remove the containers (data is kept) |
| `make clean` | Same as `down`, and remove the images |
| `make fclean` | Also remove the volumes and **erase** the data |
| `make re` | `fclean` then `make`: full rebuild from scratch |

Then open **https://fbenech.42.fr** (accept the self-signed certificate warning) and **https://fbenech.42.fr/wp-admin** for the administration panel.

See `USER_DOC.md` for end-user documentation and `DEV_DOC.md` for developer documentation.

## Resources

### References

- Docker documentation: https://docs.docker.com/
- Dockerfile best practices: https://docs.docker.com/build/building/best-practices/
- Docker Compose file reference: https://docs.docker.com/compose/compose-file/
- Docker secrets in Compose: https://docs.docker.com/compose/how-tos/use-secrets/
- NGINX documentation: https://nginx.org/en/docs/
- WordPress and WP-CLI: https://wordpress.org/documentation/ and https://wp-cli.org/
- MariaDB documentation: https://mariadb.com/kb/en/documentation/
- PHP-FPM configuration: https://www.php.net/manual/en/install.fpm.configuration.php

### Use of AI

AI (Claude) was used as a learning and troubleshooting assistant:

- explaining concepts (containers vs VMs, PID 1, volumes, secrets, TLS, php-fpm);
- planning the steps of the project and the directory structure;
- drafting a first version of the Dockerfiles, configuration files, startup scripts, `docker-compose.yml` and Makefile, which were then tested, debugged and reviewed;
- helping to diagnose errors (VM clock drift, apt repository, MariaDB initialisation, restart policy testing);
- helping to draft this documentation.

All generated content was tested and reviewed, and is understood and explained by the author.

# Developer Documentation

This document explains how to set up, build and maintain the Inception stack.

## 1. Set up the environment from scratch

### Prerequisites

- A Linux virtual machine (Debian)
- Docker Engine and the Docker Compose plugin
- `make`, `git`, `curl`, and `sudo` rights

Check the installation:

```bash
docker --version
docker compose version
make --version
```

### Configuration files

```
.
├── Makefile
├── secrets/                     (ignored by Git)
│   ├── db_password.txt
│   ├── db_root_password.txt
│   ├── wp_admin_password.txt
│   └── wp_user_password.txt
└── srcs/
    ├── docker-compose.yml
    ├── .env                     (ignored by Git)
    └── requirements/
        ├── mariadb/   (Dockerfile, conf/50-server.cnf, tools/init.sh)
        ├── nginx/     (Dockerfile, conf/nginx.conf, tools/start.sh)
        └── wordpress/ (Dockerfile, conf/www.conf, tools/setup.sh)
```

### Domain name

Add this line to `/etc/hosts`:

```
127.0.0.1   fbenech.42.fr
```

### Secrets and environment

Create the four files in `secrets/` (one password per file) and `srcs/.env`:

```
DOMAIN_NAME=fbenech.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
WP_TITLE=Inception
WP_ADMIN_USER=<administrator name, must not contain "admin">
WP_ADMIN_EMAIL=<email>
WP_USER=<second user name>
WP_USER_EMAIL=<email>
```

`secrets/` and `srcs/.env` must stay in `.gitignore`. Never commit credentials.

## 2. Build and launch

The Makefile wraps Docker Compose (`docker compose -f srcs/docker-compose.yml`):

| Command | Effect |
|---|---|
| `make` | Create `/home/fbenech/data/{mariadb,wordpress}`, build images, start containers |
| `make down` | Stop and remove containers and network (data is kept) |
| `make clean` | `down` and remove the images |
| `make fclean` | `clean`, remove the volumes and erase the data folders |
| `make re` | `fclean` then `make` |

The first start takes a few minutes: images are built, then `setup.sh` downloads and installs WordPress.

## 3. Manage containers and volumes

```bash
docker compose -f srcs/docker-compose.yml ps          # status
docker compose -f srcs/docker-compose.yml logs -f     # follow logs
docker compose -f srcs/docker-compose.yml restart nginx
docker exec -it mariadb bash                          # shell in a container
docker exec -it mariadb mariadb -uroot                # SQL shell
docker images                                         # images (tagged 1.0, never latest)
docker volume ls                                      # srcs_mariadb_data, srcs_wordpress_data
docker volume inspect srcs_wordpress_data             # shows the device path
docker network ls                                     # srcs_inception
```

Useful checks:

```bash
openssl s_client -connect fbenech.42.fr:443 -tls1_2 < /dev/null    # TLS 1.2 works
openssl s_client -connect fbenech.42.fr:443 -tls1_3 < /dev/null    # TLS 1.3 works
curl -I http://fbenech.42.fr                                       # port 80 must be refused
```

Restart policy test (a real crash, not `docker kill`, which Docker treats as a manual stop):

```bash
sudo kill -9 $(docker inspect -f '{{.State.Pid}}' nginx)
sleep 10 && docker ps
```

## 4. Where data is stored and how it persists

Two Docker **named volumes**, declared in `docker-compose.yml` with `driver_opts` so that their data lands on the host:

| Volume | Container path | Host path |
|---|---|---|
| `mariadb_data` | `/var/lib/mysql` | `/home/fbenech/data/mariadb` |
| `wordpress_data` | `/var/www/html` | `/home/fbenech/data/wordpress` |

- `make down` keeps this data: the next `make` finds it and does not reinstall anything.
- `init.sh` (MariaDB) creates the database and users only if the database does not exist yet.
- `setup.sh` (WordPress) installs WordPress only if `wp-config.php` does not exist yet.
- `make fclean` removes the volumes and the content of `/home/fbenech/data`, so the next start is a fresh install.

## 5. Architecture notes

- All containers are on the `inception` bridge network and reach each other by service name (`mariadb`, `wordpress`).
- Only NGINX publishes a port (443). php-fpm (9000) and MariaDB (3306) are internal.
- Each service ends its startup script with `exec` so the real daemon is PID 1 and runs in the foreground.
- Passwords are Docker secrets, mounted in `/run/secrets/` and read at startup, never written in a Dockerfile or an image.
- `restart: always` restarts containers after a crash.

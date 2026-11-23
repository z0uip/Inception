# User Documentation

This document explains how to use the Inception stack as an end user or administrator.

## 1. Services provided

| Service | What it does |
|---|---|
| **NGINX** | Web server and the only entry point. Serves the website over HTTPS (port 443, TLSv1.2/1.3). |
| **WordPress (php-fpm)** | The website and its administration panel. |
| **MariaDB** | The database storing the articles, pages and users of WordPress. |

## 2. Start and stop the project

All commands are run from the root of the repository.

| Action | Command |
|---|---|
| Start (build if needed) | `make` |
| Stop (data is kept) | `make down` |
| Full rebuild from scratch | `make re` |
| Stop and **erase all data** | `make fclean` |

Warning: `make fclean` and `make re` delete the website and the database.

## 3. Access the website

Make sure `/etc/hosts` contains this line:

```
127.0.0.1   fbenech.42.fr
```

- Website: **https://fbenech.42.fr**
- Administration panel: **https://fbenech.42.fr/wp-admin**

The certificate is self-signed, so the browser shows a security warning. Click "Advanced", then "Proceed" (or "Accept the risk").

## 4. Credentials

Credentials are never stored in Git.

| What | Where |
|---|---|
| Database user password | `secrets/db_password.txt` |
| Database root password | `secrets/db_root_password.txt` |
| WordPress administrator password | `secrets/wp_admin_password.txt` |
| WordPress second user password | `secrets/wp_user_password.txt` |
| Usernames, domain, database name | `srcs/.env` |

The WordPress usernames are `WP_ADMIN_USER` (administrator) and `WP_USER` (author) in `srcs/.env`.

To change a password, edit the matching file in `secrets/`, then run `make re` (this rebuilds the stack and erases the data).

## 5. Check that the services are running

```bash
docker compose -f srcs/docker-compose.yml ps
```

The three containers `mariadb`, `wordpress` and `nginx` must be `Up`. Only nginx shows a published port (`0.0.0.0:443->443/tcp`).

Other checks:

```bash
docker logs nginx                                   # web server logs
docker logs wordpress                               # WordPress installation logs
docker exec wordpress wp user list --allow-root --path=/var/www/html   # WordPress users
curl -kI https://fbenech.42.fr                      # should return HTTP 200 or 302
```

If the website does not load, check that the three containers are `Up`, that `/etc/hosts` is correct, and look at the logs above.

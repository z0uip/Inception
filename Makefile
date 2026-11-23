COMPOSE = docker compose -f srcs/docker-compose.yml
DATA_DIR = /home/fbenech/data

all:
	@mkdir -p $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress
	@$(COMPOSE) up -d --build

down:
	@$(COMPOSE) down

clean:
	@$(COMPOSE) down --rmi all

fclean: clean
	@docker volume rm srcs_mariadb_data srcs_wordpress_data 2>/dev/null || true
	@sudo rm -rf $(DATA_DIR)/mariadb/* $(DATA_DIR)/wordpress/*

re: fclean all

.PHONY: all down clean fclean re

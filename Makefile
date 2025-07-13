
.PHONY: dev prod down logs prune nuke setup help migrate-dev migrate-prod migration test format lint

define ASCII_DEV
	@echo "\033[32m"
	@echo " ⡋⣡⣴⣶⣶⡀⠄⠄⠙⢿⣿⣿⣿⣿⣿⣴⣿⣿⣿⢃⣤⣄⣀⣥⣿"
	@echo " ⢸⣇⠻⣿⣿⣿⣧⣀⢀⣠⡌⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠿⠿⣿⣿"
	@echo " ⢸⣿⣷⣤⣤⣤⣬⣙⣛⢿⣿⣿⣿⣿⣿⣿⡿⣿⣿⡍⠄⠄⢀⣤⣄⠉"
	@echo " ⣖⣿⣿⣿⣿⣿⣿⣿⣿⣿⢿⣿⣿⣿⣿⣿⢇⣿⣿⡷⠶⠶⢿⣿⣿⠇⢀"
	@echo " ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣽⣿⣿⣿⡇⣿⣿⣿⣿⣿⣿⣷⣶⣥⣴"
	@echo " ⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿"
	@echo " ⣦⣌⣛⣻⣿⣿⣧⠙⠛⠛⡭⠅⠒⠦⠭⣭⡻⣿⣿⣿⣿⣿⣿⣿⣿⡿⠃⠄"
	@echo " ⣿⣿⣿⣿⣿⣿⣿⡆⠄⠄⠄⠄⠄⠄⠄⠄⠹⠈⢋⣽⣿⣿⣿⣿⣵⣾"
	@echo " ⣿⣿⣿⣿⣿⣿⣿⣿⠄⣴⣿⣶⣄⠄⣴⣶⠄⢀⣾⣿⣿⣿⣿⣿⣿⠃⠄⠄"
	@echo " ⠈⠻⣿⣿⣿⣿⣿⣿⡄⢻⣿⣿⣿⠄⣿⣿⡀⣾⣿⣿⣿⣿⣛⠛⠁"
	@echo " ⠄⠄⠈⠛⢿⣿⣿⣿⠁⠞⢿⣿⣿⡄⢿⣿⡇⣸⣿⣿⠿⠛⠁⠄"
	@echo " ⠄⠄⠄⠄⠄⠉⠻⣿⣿⣾⣦⡙⠻⣷⣾⣿⠃⠿⠋⠁⠄"
	@echo "\033[0m"
endef

define ASCII_PROD
	@echo "\033[36m"
	@echo " ⣿⣿⣿⡷⠊⡢⡹⣦⡑⢂⢕⢂⢕⢂⢕⢂⠕⠔⠌⠝⠛⠶⠶⢶⣦⣄⢂⢕⢂⢕" 
	@echo " ⣿⣿⠏⣠⣾⣦⡐⢌⢿⣷⣦⣅⡑⠕⠡⠐⢿⠿⣛⠟⠛⠛⠛⠛⠡⢷⡈⢂⢕⢂" 
	@echo " ⠟⣡⣾⣿⣿⣿⣿⣦⣑⠝⢿⣿⣿⣿⣿⣿⡵⢁⣤⣶⣶⣿⢿⢿⢿⡟⢻⣤⢑⢂" 
	@echo " ⣾⣿⣿⡿⢟⣛⣻⣿⣿⣿⣦⣬⣙⣻⣿⣿⣷⣿⣿⢟⢝⢕⢕⢕⢕⢽⣿⣿⣷⣔" 
	@echo " ⣿⣿⠵⠚⠉⢀⣀⣀⣈⣿⣿⣿⣿⣿⣿⣿⣿⣿⣗⢕⢕⢕⢕⢕⢕⣽⣿⣿⣿⣿" 
	@echo " ⢷⣂⣠⣴⣾⡿⡿⡻⡻⣿⣿⣴⣿⣿⣿⣿⣿⣿⣷⣵⣵⣵⣷⣿⣿⣿⣿⣿⣿⡿" 
	@echo " ⢌⠻⣿⡿⡫⡪⡪⡪⡪⣺⣿⣿⣿⣿⣿⠿⠿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠃" 
	@echo " ⠣⡁⠹⡪⡪⡪⡪⣪⣾⣿⣿⣿⣿⠋⠐⢉⢍⢄⢌⠻⣿⣿⣿⣿⣿⣿⣿⣿⠏⠈" 
	@echo " ⡣⡘⢄⠙⣾⣾⣾⣿⣿⣿⣿⣿⣿⡀⢐⢕⢕⢕⢕⢕⡘⣿⣿⣿⣿⣿⣿⠏⠠⠈" 
	@echo " ⠌⢊⢂⢣⠹⣿⣿⣿⣿⣿⣿⣿⣿⣧⢐⢕⢕⢕⢕⢕⢅⣿⣿⣿⣿⡿⢋⢜⠠⠈" 
	@echo "\033[0m"
endef

define ASCII_DOWN
	@echo "\033[31m"
	@echo " ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣀⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀" 
	@echo " ⠀⠀⠀⠀⠠⣀⣀⣀⣀⣀⣤⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣦⣤⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀" 
	@echo " ⠀⠀⠀⠀⠴⣋⢝⣼⡿⢛⣭⣿⣿⡿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣤⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀" 
	@echo " ⠀⠀⠀⠀⠀⣱⣿⠟⣷⣿⠛⠉⠀⣠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀" 
	@echo " ⠀⠀⠀⠀⠀⠘⡟⠰⣟⠻⡀⠀⣰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀" 
	@echo " ⢠⠆⠤⠤⠤⠋⠀⣰⡾⣄⠑⢴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀" 
	@echo " ⡈⠀⠀⠀⠀⢀⣼⠟⠙⠭⠷⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀" 
	@echo " ⢧⣄⡀⠀⠀⡾⠁⠀⠀⠀⠜⠁⢹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀" 
	@echo " ⠀⠙⣿⠀⠈⠃⠀⠀⠀⡌⠀⠀⢨⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀" 
	@echo " ⠀⠀⢹⡇⠘⠀⠀⠀⡜⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀" 
	@echo " ⠀⢠⣼⡿⠂⠀⠀⢰⠁⠀⠀⣸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀" 
	@echo " ⢴⡉⠁⠀⠀⠀⠀⠸⠀⠀⢰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀" 
	@echo " ⣼⠀⠀⠀⠀⠀⠀⡀⠀⢀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡏⢸⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀" 
	@echo " ⠈⠁⠐⠒⠐⣤⡀⠂⠀⣸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⢀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀" 
	@echo " ⠀⠀⠀⠰⠀⣿⣿⣧⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡃⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀" 
	@echo " ⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⡇⡸⢆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀" 
	@echo " ⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣟⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⠁⠈⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀" 
	@echo " ⠀⠀⠀⠁⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣾⣿⣿⣿⣿⣿⣿⡿⣿⡀⠀⠐⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀" 
	@echo " ⠀⠀⠀⠀⡿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⣿⣿⣿⢹⣧⠀⠑⢴⡀⠀⠀⠀⠀⠀⠀⠀⠀" 
	@echo " ⠀⠀⠀⠀⡇⢻⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣾⣿⣿⣷⣿⣆⠀⠀⠑⢄⠀⠀⠀⠀⠀⠀⠀" 
	@echo " ⠀⠀⠀⠀⣷⣧⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣯⡻⣿⣿⣿⣦⣀⠀⠀⠣⡀⠀⠀⠀⠀⠀" 
	@echo " ⠀⠀⠀⠀⡏⣻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣿⣿⣯⣿⣿⣷⣦⣀⣈⡀⠀⠀⠀⠀" 
	@echo " ⠀⠀⠀⠀⢆⣼⠸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡛⠿⣿⣶⣄⠀⠀" 
	@echo " ⠀⠀⠀⠀⢸⣇⢰⡟⠛⠻⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢿⣿⣶⣬⣧⣉⠻⠄" 
	@echo "\033[0m"
endef

define ASCII_LOGS
	@echo "\033[34m"
	@echo " ⣇⣿⠘⣿⣿⣿⡿⡿⣟⣟⢟⢟⢝⠵⡝⣿⡿⢂⣼⣿⣷⣌⠩⡫⡻⣝⠹⢿⣿⣷" 
	@echo " ⡆⣿⣆⠱⣝⡵⣝⢅⠙⣿⢕⢕⢕⢕⢝⣥⢒⠅⣿⣿⣿⡿⣳⣌⠪⡪⣡⢑⢝⣇" 
	@echo " ⡆⣿⣿⣦⠹⣳⣳⣕⢅⠈⢗⢕⢕⢕⢕⢕⢈⢆⠟⠋⠉⠁⠉⠉⠁⠈⠼⢐⢕⢽" 
	@echo " ⡗⢰⣶⣶⣦⣝⢝⢕⢕⠅⡆⢕⢕⢕⢕⢕⣴⠏⣠⡶⠛⡉⡉⡛⢶⣦⡀⠐⣕⢕" 
	@echo " ⡝⡄⢻⢟⣿⣿⣷⣕⣕⣅⣿⣔⣕⣵⣵⣿⣿⢠⣿⢠⣮⡈⣌⠨⠅⠹⣷⡀⢱⢕" 
	@echo " ⡝⡵⠟⠈⢀⣀⣀⡀⠉⢿⣿⣿⣿⣿⣿⣿⣿⣼⣿⢈⡋⠴⢿⡟⣡⡇⣿⡇⡀⢕" 
	@echo " ⡝⠁⣠⣾⠟⡉⡉⡉⠻⣦⣻⣿⣿⣿⣿⣿⣿⣿⣿⣧⠸⣿⣦⣥⣿⡇⡿⣰⢗⢄" 
	@echo " ⠁⢰⣿⡏⣴⣌⠈⣌⠡⠈⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣬⣉⣉⣁⣄⢖⢕⢕⢕" 
	@echo " ⡀⢻⣿⡇⢙⠁⠴⢿⡟⣡⡆⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣵⣵⣿" 
	@echo " ⡻⣄⣻⣿⣌⠘⢿⣷⣥⣿⠇⣿⣿⣿⣿⣿⣿⠛⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿" 
	@echo " ⣷⢄⠻⣿⣟⠿⠦⠍⠉⣡⣾⣿⣿⣿⣿⣿⣿⢸⣿⣦⠙⣿⣿⣿⣿⣿⣿⣿⣿⠟" 
	@echo " ⡕⡑⣑⣈⣻⢗⢟⢞⢝⣻⣿⣿⣿⣿⣿⣿⣿⠸⣿⠿⠃⣿⣿⣿⣿⣿⣿⡿⠁⣠" 
	@echo " ⡝⡵⡈⢟⢕⢕⢕⢕⣵⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣶⣿⣿⣿⣿⣿⠿⠋⣀⣈⠙" 
	@echo " ⡝⡵⡕⡀⠑⠳⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠛⢉⡠⡲⡫⡪⡪⡣ " 
	@echo "\033[0m"
endef

define ASCII_PRUNE
	@echo "\033[35m"
	@echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⠀⠤⠤⠤⠤⠄⣀⠀⠀⠀⠀⠀⠀⠀⠀"
	@echo "⠀⠀⠀⠀⠀⠀⠀⠀⢀⡠⠒⠉⠀⠀⠀⠀⠀⠀⠀⠀⠈⠑⠲⡈⠉⠁⠢⡀"
	@echo "⠀⠄⠂⠈⠁⠐⠂⠴⠉⠀⠀⠀⠀⠀⡖⠒⡄⠀⠀⢎⠑⡄⠀⠈⠢⡀⠀⢸"
	@echo "⡌⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢷⣤⣿⠀⠀⢸⣶⣿⠀⠀⠀⠘⡄⡜"
	@echo "⢣⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⡟⣿⠆⠀⠀⢻⣻⠇⢀⠤⣀⠘⡅"
	@echo "⠀⠢⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢢⠀⠉⢊⣠⣴⣶⣦⣥⡀⠘⠦⠈⠀⢡"
	@echo "⠀⠀⠀⠑⢢⠀⠀⠀⠀⠀⠀⠀⠀⠁⠀⣴⣿⣿⣿⣿⣿⣿⣿⣆⠀⠀⠀⢸"
	@echo "⠀⠀⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠈"
	@echo "⠀⠀⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⡿⠋⠉⠀⠀⠀⠉⠻⣿⣿⡇⠀⠀⡆"
	@echo "⠀⠀⠀⠀⢰⣧⡀⠀⠀⠀⠀⠀⠀⠰⡇⠀⠀⠀⠀⠀⠀⠀⢘⣿⠇⠀⡜⠀"
	@echo "⠀⠀⠀⠀⣼⣿⣷⡄⠀⠀⠀⠀⠀⠀⣧⠀⠀⠀⠀⠀⠀⢀⣼⡟⢀⠎⠀⠀"
	@echo "⠀⠀⠀⠀⢹⣿⣿⣿⣦⣄⠀⠀⠀⠀⠘⢿⣦⣴⣤⣴⣿⡿⢋⣠⡏⠀⠀⠀"
	@echo "⠀⠀⠀⠀⠸⣿⣿⣿⣿⣿⣿⣶⣤⠤⠄⠀⠉⠉⢍⣩⣴⣶⣿⣿⠃⠀⠀⠀"
	@echo "⠀⠀⠀⠀⠀⠹⣿⣿⣿⣿⣿⡿⠃⠀⠀⠀⠀⠀⠀⠙⠛⠛⠛⠁⠀⠀⠀⠀"
	@echo "⠀⠀⠀⠀⠀⠀⠈⠛⠛⠛⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
	@echo "\033[0m"
endef

define ASCII_NUKE
	@echo "\033[31;5;7m" 
	@echo " ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀" 
	@echo " ⠀⠀⠀⠀⠀⠀⣄⠀⠀⠀⣦⣤⣾⣿⠿⠛⣋⣥⣤⣀⠀⠀⠀⠀" 
	@echo " ⠀⠀⠀⠀⡤⡀⢈⢻⣬⣿⠟⢁⣤⣶⣿⣿⡿⠿⠿⠛⠛⢀⣄⠀" 
	@echo " ⠀⠀⢢⣘⣿⣿⣶⣿⣯⣤⣾⣿⣿⣿⠟⠁⠄⠀⣾⡇⣼⢻⣿⣾" 
	@echo " ⣰⠞⠛⢉⣩⣿⣿⣿⣿⣿⣿⣿⣿⠋⣼⣧⣤⣴⠟⣠⣿⢰⣿⣿" 
	@echo " ⣶⡾⠿⠿⠿⢿⣿⣿⣿⣿⣿⣿⣿⣈⣩⣤⡶⠟⢛⣩⣴⣿⣿⡟" 
	@echo " ⣠⣄⠈⠀⣰⡦⠙⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣟⡛⠛⠛⠁" 
	@echo " ⣉⠛⠛⠛⣁⡔⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠥⠀⠀" 
	@echo " ⣭⣏⣭⣭⣥⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⢠" 
	@echo "\033[0m"
endef

define ASCII_SETUP
	@echo "\033[36m"
	@echo " ⠀⠀⠀⠀⠀⢀⣴⣿⣿⣿⣿⣿⣿⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀" 
	@echo " ⠀⠀⠀⠀⠀⣼⣿⣿⣟⣻⣿⡏⠻⣿⣿⣦⡀⠀⠀⠀⠀⠀⠀" 
	@echo " ⠀⠀⠀⠀⣼⣿⣿⣿⢿⣿⣿⠗⠀⢹⣿⣿⣟⡄⠀⠀⠀⠀⠀" 
	@echo " ⠀⠀⠀⢰⣿⣿⣇⣻⡮⢟⠛⠛⠛⣻⣿⣿⣿⠘⡀⠀⠀⠀⠀" 
	@echo " ⠀⠀⠀⢸⣿⣿⡿⣷⡰⠀⠀⣀⢉⣸⣿⣿⣿⡶⠁⠀⠀⠀⠀" 
	@echo " ⠀⠀⠀⢸⣿⣿⣽⣶⣦⡀⢾⣏⠐⣿⣿⣿⠿⠀⠀⠀⠀⠀⠀" 
	@echo " ⠀⠀⠀⠈⢟⡿⠿⠟⠿⣙⡄⠈⠓⡄⠉⠀⠀⠀⠀⠀⠀⠀⠀" 
	@echo " ⠀⠀⠀⠀⢰⠃⠀⠀⠀⠈⠉⡖⠀⡟⠢⡄⠀⡀⠀⠀⠀⠀⠀" 
	@echo " ⠀⠀⠀⠀⢸⠀⠀⠀⢢⠀⢀⡆⠀⡇⠀⠈⠢⡈⠠⠀⠀⠀⠀" 
	@echo " ⠀⠀⠀⠀⠘⡆⠀⠀⠈⣧⢸⠀⠀⡇⠢⡀⠀⠈⠦⡇⠀⠀⠀" 
	@echo " ⠀⠀⠀⠀⠀⠹⡆⠀⠀⢨⠃⠀⠀⣇⠀⠈⠢⠀⠀⠈⢢⠀⠀" 
	@echo " ⠀⠀⠀⠀⠀⠀⠑⡀⠀⠇⠀⠀⠀⡇⠳⡀⠀⢱⠀⠀⠀⢳⡀" 
	@echo " ⠀⠀⠀⠀⠀⠀⠀⠱⣾⠀⠀⠀⠀⡇⠀⠑⡀⡸⠄⠀⠀⣜⢘" 
	@echo " ⠀⠀⠀⠀⠀⠀⠀⠀⠙⣄⠀⠀⣰⢀⣤⡤⠼⣧⣤⣤⡾⠟⠁" 
	@echo " ⠀⠀⠀⠀⠀⠀⠀⠀⢀⣼⠑⠒⠉⠉⠁⠀⢠⠀⣽⠁⠀⠀⠀" 
	@echo " ⠀⠀⠀⠀⠀⢀⡠⠔⠉⠈⠣⠀⠀⠀⠀⠀⠀⣰⡏⠀⠀⠀⠀" 
	@echo " ⠀⠀⠀⢠⡖⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠆⠀⡇⠃⠀⠀⠀⠀" 
	@echo " ⠀⠀⣴⠛⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⡜⠀⢀⠃⠃⠀⠀⠀⠀" 
	@echo " ⠀⡼⠃⣸⡉⠢⠀⠀⢆⠀⠀⠀⠀⠀⠁⠀⠼⣦⡆⠀⠀⠀⠀" 
	@echo " ⢰⠁⠀⠏⡇⠀⠈⠐⢬⣄⠀⠀⠀⠀⠀⢀⣼⢿⠅⠀⠀⠀⠀" 
	@echo " ⢸⠀⢠⢀⠁⠀⠀⠀⠀⢇⠈⠁⢒⠖⠊⠉⠀⠘⡆⠀⠀⠀⠀" 
	@echo " ⢸⠀⡜⡘⠀⠀⠀⠀⠀⠘⣦⠔⠁⠀⠀⠀⠀⠀⠸⡄⠀⠀" 
	@echo "\033[0m"
endef

define ASCII_TEST
	@echo "\033[35m"
	@echo "⠀⠀⠀⢀⡴⠛⠉⠙⠲⣤⣤⠴⠖⠚⠋⠉⠉⠛⠒⠦⣤⡀⠀⠀⠀⠀⠀⠀⠀⠀"
	@echo "⠀⠀⠀⣾⠁⠀⠀⣠⠞⠉⢀⡷⡀⠀⠀⠀⠀⠀⡀⠀⠀⠙⢷⣤⡤⠤⠤⣤⡀⠀"
	@echo "⠀⠀⠀⣧⠀⢠⠞⠁⠀⠀⡎⣇⢿⠀⠀⣶⢊⡏⠁⠀⠀⠰⠟⠁⠀⠀⠀⠀⠹⡄"
	@echo "⠀⠀⠀⢸⣤⠏⡠⢤⡀⠀⡃⢀⠇⠀⢸⠈⠉⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡇"
	@echo "⠀⠀⠀⢠⡏⠀⠘⠤⠽⠀⢣⣊⣀⠀⠸⣀⠜⣀⠠⣀⠀⠀⠀⠀⠀⠀⠀⠀⢠⠇"
	@echo "⠀⠀⠀⢸⠀⠀⠀⠀⠀⡔⠉⠀⠀⠉⠢⡀⠀⠧⠠⠜⠀⠀⠀⠀⠀⠀⠀⣠⠟⠀"
	@echo "⠀⠀⠀⢸⡀⠀⠀⠀⠸⠀⠀⢀⠔⠊⠉⠙⡄⠀⠀⠀⠀⠀⠀⠀⠀⣠⡾⠁⠀⠀"
	@echo "⠀⠀⠀⠘⣇⠀⠀⠀⢀⠀⡰⠃⠀⠀⠀⠀⢹⠀⠀⠀⠀⠀⠀⠀⠀⢰⠇⠀⠀⠀"
	@echo "⠀⠀⣠⠞⢻⡀⠀⠀⠸⣰⠁⠀⠀⠀⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀⢠⣏⠀⠀⠀⠀"
	@echo "⠀⣼⠃⠀⠀⢳⡄⠀⠀⢳⠀⠀⠀⠀⠀⠀⢠⠃⠀⠀⠀⠀⠀⣠⠏⠈⠳⣄⠀⠀"
	@echo "⢰⡇⠀⠀⠀⠀⠙⢦⣀⠀⠱⢄⡀⠀⠀⣠⠋⠀⠀⠀⢀⣠⠞⠁⠀⠀⠀⠘⡆⠀"
	@echo "⠈⣧⡀⠀⠀⠀⠀⠀⢉⣳⢦⣤⣈⣉⣉⣀⣠⣤⣶⠚⠋⠀⠀⠀⠀⠀⠀⠀⢻⠀"
	@echo "⠀⠈⠙⠓⠲⠖⠚⠋⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⢦⣄⡀⠀⠀⠀⠀⣀⡾⠀"
	@echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠙⠛⠛⠋⠉⠀⠀"
	@echo "\033[0m"
endef

define ASCII_QUALITY
	@echo "\033[33m"
	@echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠"
	@echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡠⠔⠊⠁⠀"
	@echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⠁⠀⠀⠀⠀"
	@echo "⠀⠀⠀⠀⠀⣀⠔⠊⠁⠀⠀⠀⠀⠈⠑⠢⣀⠀⠀⠀⢀⣀⡎⠀⠀⠀⢀⡴"
	@echo "⠀⠀⠀⢀⠎⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠐⠒⠓⡼⠀⠀⠀⡴⠋⠀"
	@echo "⠀⠀⢀⠃⢀⡀⠤⠄⠐⠒⠒⠒⠒⠂⠠⠤⣣⡀⣀⠤⢪⠃⠀⢠⠊⠀⠀⠀"
	@echo "⠀⢀⠞⠉⠀⠀⣀⣀⠀⠀⠀⠠⠀⠀⣀⡀⠀⢹⠀⢀⠎⠀⡰⠁⠀⠀⠀⠀"
	@echo "⠀⠸⣠⠒⢌⠁⠀⠀⠀⡠⠂⠀⠀⠀⢠⠚⡍⠺⢀⠎⢀⡜⠀⠀⠀⠀⠀⠀"
	@echo "⠀⡠⢼⠀⣦⣑⠀⢠⣎⣼⠀⠀⠀⠀⠈⠀⣸⢿⠟⣱⡎⠀⠀⠀⠀⠀⠀⠀"
	@echo "⢰⡁⢸⠀⠹⠿⠀⠀⢿⡟⠀⠀⠀⠀⠘⡦⢿⣧⣀⣼⠇⠉⡹⠀⠀⠀⠀⠀"
	@echo "⠀⠑⣒⡆⠀⠀⢠⡀⠀⠀⠀⠀⠀⠀⠀⢄⠀⠉⢉⠧⠠⠔⠁⠀⠀⠀⠀⠀"
	@echo "⡔⠉⠀⠈⠢⡀⠀⠀⠀⠀⢀⠖⠉⠀⠈⢏⠽⢍⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀"
	@echo "⠣⣀⠀⠀⠀⢈⡲⠤⠤⠤⠼⣆⠀⠀⠀⠀⠀⠀⢡⠀⠀⠀⠀⠀⠀⠀⠀⠀"
	@echo "⠀⠀⠈⠉⠉⠀⠀⠀⠀⠀⠀⠈⠒⠤⠄⠀⠀⠠⠜⠀⠀⠀⠀⠀⠀⠀⠀⠀"
	@echo "\033[0m"
endef

define ASCII_MIGRATE
	@echo "\033[94m" 
	@echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⢀⣤⠤⠤⠴⠤⢤⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
	@echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⡴⠚⠉⠀⠀⠀⠀⠀⠀⠀⠀⠉⠑⠲⣄⠀⠀⠀⠀⠀⠀"
	@echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⠞⢀⣄⠀⠀⣠⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠹⣆⠀⠀⠀⠀"
	@echo "⠀⠀⠀⠀⠀⠀⠀⠀⢠⠏⣾⣠⠎⠀⣸⠁⣸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⡆⠀⠀⠀"
	@echo "⠀⠀⠀⠀⠀⠀⠀⢰⠃⣾⣿⡏⠀⢰⣿⣿⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⡄⠀⠀"
	@echo "⠀⠀⠀⠀⠀⠀⠀⣾⠷⠻⠟⠀⠀⠸⣿⠏⠀⠀⢠⣤⣤⣀⣀⠀⠀⠀⠀⠀⠀⠀⢱⠀⠀"
	@echo "⢠⡴⢦⣤⣄⠀⡇⠀⠀⠀⢰⣶⣶⡄⠀⠀⠀⠈⠛⠛⠯⠿⠃⠀⠀⠀⠀⠀⠀⢸⡘⠀⠀"
	@echo "⢸⣹⢿⣾⣹⢿⣿⠀⠀⠀⠀⠹⠏⠀⠀⠀⠀⠀⠀⠀⣀⣶⣆⣀⠀⠀⠀⠀⠀⠀⣿⡀⠀"
	@echo "⠘⣭⢷⣫⡽⣯⢿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⢶⣻⠽⣶⣫⣟⣷⡄⠀⠀⠀⠀⠘⢖⡀"
	@echo "⠀⠘⣯⢷⣻⣽⣻⣿⡄⠀⠀⠀⠀⠀⠀⢀⣼⣳⣻⢞⣟⣳⡽⣞⣳⢿⡀⠀⠀⠀⠀⠘⣡"
	@echo "⠀⠀⠈⢯⢷⣞⣷⣻⣿⣄⠀⠀⠀⠀⢠⣿⣳⡽⣳⣟⣾⡳⣿⠽⣯⣟⣧⠀⠀⠀⠀⠀⠸"
	@echo "⠀⠀⠀⠀⠙⢞⣾⣳⢿⣿⣷⢤⠀⠈⢿⣳⣳⢟⣳⡽⣶⣻⣽⡻⣗⣯⠷⡄⠀⠀⠀⠀⡬"
	@echo "⠀⠀⠀⠀⠀⠀⠱⢏⣿⡿⠁⠀⠉⠶⣸⣷⢏⡿⣷⢿⢷⡿⣶⢿⣹⡎⠁⠈⠳⠶⠶⠊⠀"
	@echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠫⣿⣝⡷⣯⠿⣝⣯⡿⠋⠀⠀⠀⠀⠀⠀⠀⠀"
	@echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠙⠛⠛⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
	@echo "\033[0m"
endef


# ==============================================================================
# MAIN COMMANDS
# ==============================================================================

help:
	@echo "\033[36mProject Makefile\033[0m"
	@echo "--------------------------"
	@echo ""
	@echo "\033[1m\033[33mDocker Environment:\033[0m"
	@echo "  \033[32mdev\033[0m          - Start development environment (detached)."
	@echo "  \033[36mprod\033[0m         - Start production environment (detached)."
	@echo "  \033[31mdown\033[0m         - Stop all containers."
	@echo "  \033[34mlogs\033[0m         - Follow container logs."
	@echo ""
	@echo "\033[1m\033[33mDocker Management:\033[0m"
	@echo "  \033[35mprune\033[0m        - Clean Docker system (keeps volumes)."
	@echo "  \033[31;5mnuke\033[0m         - \033[1;31mDANGER:\033[0m Clean everything including volumes."
	@echo ""
	@echo "\033[1m\033[33mProject & Database:\033[0m"
	@echo "  \033[36msetup\033[0m        - Run initial project setup (from setup.sh)."
	@echo "  \033[94mmigrate-dev\033[0m  - Apply database migrations for the dev environment."
	@echo "  \033[94mmigrate-prod\033[0m - Apply database migrations for the prod environment."
	@echo "  \033[94mmigration\033[0m   - Create a new Alembic migration file."
	@echo ""
	@echo "\033[1m\033[33mCode Quality:\033[0m"
	@echo "  \033[35mtest\033[0m         - Run the test suite inside the dev container."
	@echo "  \033[33mformat\033[0m       - Format both backend and frontend code."
	@echo "  \033[33mlint\033[0m         - Lint both backend and frontend code."

# --- Development environment ---
dev:
	$(call ASCII_DEV)
	@echo "\033[32m🚀 Starting development environment...\033[0m"
	@docker-compose -f infra/dev/docker-compose.yml up --build -d
	@echo "\033[32m✅ Development environment started! Run 'make logs' to see logs.\033[0m"
	$(call ASCII_DEV)

# --- Production environment ---
prod:
	$(call ASCII_PROD)
	@echo "\033[36m🏭 Starting production environment...\033[0m"
	@docker-compose -f infra/prod/docker-compose.yml up --build -d
	@echo "\033[36m✅ Production environment started! Run 'make logs' to see logs.\033[0m"
	$(call ASCII_PROD)

# --- Stop all containers ---
down:
	$(call ASCII_DOWN)
	@echo "\033[31m🛑 Stopping all containers...\033[0m"
	@if [ -f infra/dev/docker-compose.yml ]; then \
		docker-compose -f infra/dev/docker-compose.yml down; \
	fi
	@if [ -f infra/prod/docker-compose.yml ]; then \
		docker-compose -f infra/prod/docker-compose.yml down; \
	fi
	@echo "\033[31m✅ All containers stopped.\033[0m"
	$(call ASCII_DOWN)

# --- Follow logs ---
logs:
	$(call ASCII_LOGS)
	@echo "\033[34m📜 Following container logs (Ctrl+C to exit)...\033[0m"
	@if [ -f infra/dev/docker-compose.yml ] && docker-compose -f infra/dev/docker-compose.yml ps -q | grep -q .; then \
		docker-compose -f infra/dev/docker-compose.yml logs -f; \
	elif [ -f infra/prod/docker-compose.yml ] && docker-compose -f infra/prod/docker-compose.yml ps -q | grep -q .; then \
		docker-compose -f infra/prod/docker-compose.yml logs -f; \
	else \
		echo "\033[33m🤔 No running containers found. Start with 'make dev' or 'make prod'.\033[0m"; \
	fi
	$(call ASCII_LOGS)

# --- Clean Docker system (preserves volumes) ---
prune:
	$(call ASCII_PRUNE)
	@echo "\033[35m🧹 Cleaning Docker system (preserving volumes)...\033[0m"
	@docker system prune -a -f
	@echo "\033[32m✅ Docker system cleaned.\033[0m"
	$(call ASCII_PRUNE)

# --- DANGER: Clean everything including volumes ---
nuke:
	$(call ASCII_NUKE)
	@echo "\033[1;31m⚠️  WARNING: This will delete ALL Docker data including volumes!\033[0m"
	@echo "\033[1;31m⚠️  This action cannot be undone!\033[0m"
	@read -p "Type 'DELETE EVERYTHING' to confirm: " confirm; \
	if [ "$$confirm" = "DELETE EVERYTHING" ]; then \
		echo "Nuking everything..."; \
		docker-compose -f infra/dev/docker-compose.yml down -v 2>/dev/null || true; \
		docker-compose -f infra/prod/docker-compose.yml down -v 2>/dev/null || true; \
		docker system prune -a -v -f; \
		echo "\033[32m🔥 Everything has been deleted.\033[0m"; \
	else \
		echo "Cancelled."; \
	fi
	$(call ASCII_NUKE)

# --- Initial setup ---
setup:
	$(call ASCII_SETUP)
	@echo "\033[36m🛠️  Running initial setup...\033[0m"
	@bash setup.sh
	@echo "\033[32m✅ Setup complete!\033[0m"
	$(call ASCII_SETUP)

# --- Database migrations ---
migrate-dev:
	$(call ASCII_MIGRATE)
	@echo "\033[94mApplying DEV database migrations...\033[0m"
	@docker-compose -f infra/dev/docker-compose.yml exec backend alembic upgrade head
	@echo "\033[32m✅ DEV migrations applied.\033[0m"
	$(call ASCII_MIGRATE)

migrate-prod:
	$(call ASCII_MIGRATE)
	@echo "\033[94mApplying PROD database migrations...\033[0m"
	@docker-compose -f infra/prod/docker-compose.yml exec backend alembic upgrade head
	@echo "\033[32m✅ PROD migrations applied.\033[0m"
	$(call ASCII_MIGRATE)

migration:
	$(call ASCII_MIGRATE)
	@read -p "Enter migration message: " msg; \
	echo "\033[94mCreating new migration: '$$msg'...\033[0m"; \
	docker-compose -f infra/dev/docker-compose.yml exec backend alembic revision --autogenerate -m "$$msg"
	$(call ASCII_MIGRATE)

# --- Code quality ---
test:
	$(call ASCII_TEST)
	@echo "\033[35m🧪 Running tests...\033[0m"
	@docker-compose -f infra/dev/docker-compose.yml exec backend pytest
	$(call ASCII_TEST)

format:
	$(call ASCII_QUALITY)
	@echo "\033[33m🎨 Formatting Python code with Ruff...\033[0m"
	@cd backend && ruff format .
	@echo "\033[33m🎨 Formatting TypeScript code with Biome...\033[0m"
	@cd frontend && npx @biomejs/biome format --write ./src
	@echo "\033[32m✅ Formatting complete.\033[0m"
	$(call ASCII_QUALITY)

lint:
	$(call ASCII_QUALITY)
	@echo "\033[33m🔍 Linting Python code with Ruff...\033[0m"
	@cd backend && ruff check .
	@echo "\033[33m🔍 Linting TypeScript code with Biome...\033[0m"
	@cd frontend && npx @biomejs/biome lint ./src
	@echo "\033[32m✅ Linting complete.\033[0m"
	$(call ASCII_QUALITY)

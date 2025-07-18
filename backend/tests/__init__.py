"""
PG-VENV TEST SUITE
------------------------------------------------------
©AngelaMos | Carter Perez | Connor Boetig | 2025
------------------------------------------------------
⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣠⣤⣤⠤⠤⣶⣶⣶⡤⠤⠤⠴⢤⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⡴⠛⠽⢃⣩⢭⠭⠙⠒⢒⡒⢒⣲⡥⡢⣀⠀⠹⣆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡏⠀⠠⠊⠀⠀⢸⠁⠀⠀⠇⣀⣀⣀⣈⠉⠢⠁⠀⠻⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣞⣥⠄⠀⠾⠿⢿⣾⣤⠀⠠⣞⣩⠾⣿⠿⠵⢰⣆⣠⣒⠿⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⡟⢻⠽⢲⢲⣤⠆⠀⣸⠇⠀⠀⣈⠀⠀⠈⠓⠒⠚⣋⣧⡈⢳⢸⢹⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⡮⣒⣼⣇⠀⠔⠾⣅⢀⠠⠶⠍⡿⢁⣁⣤⢶⠟⢉⣼⠟⡜⡸⣸⠃⠀⠀⠀⠀⠀⠀⠀
⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⠀⣿⢹⠓⡶⠤⢼⠯⢤⠴⠖⠛⣏⣁⣤⣾⠟⡿⠃⠀⣈⣾⣷⣶⣤⣄⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⣿⣿⣿⣷⣶⣾⣶⣾⣶⣶⠾⣿⠋⠁⣸⡞⠁⠀⢀⣿⣿⣿⣿⣿⣿⣿⣿⣦⣄⠀⠀⠀⠀⠀⠀⠀
⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⡄⠿⣿⣻⡹⡏⠹⡏⠉⣿⠀⣀⣸⡷⠞⡉⣄⠠⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⠀⠀
⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡿⠁⣀⠊⣉⠛⠻⠿⠿⠿⠛⢉⣉⣥⠢⢕⣮⣷⣿⣿⣿⠟⠀⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⠀⠀⠀⠀⠀⠀⠀
⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠗⠩⢀⡠⠤⢌⡩⠬⠍⠘⠛⡈⣉⣴⣿⢿⣿⠟⣺⣿⠏⠀⠀⠘⣿⣿⠹⣿⣿⣿⣿⣿⣿⣿⣧⠀⠀⠀⠀
⡁⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⠃⠀⠤⠤⠤⣉⢢⣤⡤⠶⢞⣿⣿⣿⡿⠃⣿⢧⣤⢿⠟⠀⠀⠀⠀⠘⣿⡂⠹⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡇⠀⠀⣀⣀⣀⠀⡇⠀⠀⠀⢸⣿⣿⣿⢱⡏⣸⣿⣿⣷⠁⠀⠀⠀⠀⠰⣎⣿⣹⢿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠁⠀⠀⠀⠀⠀⠀⠀⠀⢠⠃⠀⠀⠀⠀⠀⢹⠁⠀⠀⠀⢸⣿⣿⡏⡜⢰⣿⣿⣿⣿⡆⠀⠀⠀⠀⣰⣿⣿⣿⣧⠹⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠁⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⠀⠀⠈⠹⡖⠁⠀⠀⠀⠀⢸⣿⣿⡇⣇⢸⡿⠻⣿⣿⡇⠀⠀⠀⠀⣿⣿⣿⣿⣿⠀⢻⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀
⠁⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⠀⠀⠀⣸⠃⠀⠀⠀⠀⠀⢸⣿⣿⠇⠀⠀⢣⣠⣾⡿⠁⠀⠀⠀⠀⢏⠀⣹⣿⡿⠀⣼⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀
⠁⠀⠀⠀⠀⠀⠀⠀⢀⠇⠀⠀⠀⡞⠁⠀⠀⠀⠀⠀⠀⢸⣿⣿⠀⠂⠀⠀⠈⠉⠀⠀⠀⠀⠀⠀⠈⠛⠿⠋⠁⠀⢸⣿⣿⣿⣿⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⡁⠀⠀⠀⠀⠀⠀⠀⡸⠀⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠐⣺⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⡀⠀⠀⠀⠀⠀⠀⢀⠇⠀⠀⠀⡆⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⢸⠀⠀⠂⢰⠀⠀⠀⠀⢀⣴⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⡀⠀⠀⠀⠀⠀⠀⢸⠀⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣷⣤⣀⠀⠀⡣⢀⠠⠃⠀⠀⣀⣴⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⡀⠀⠀⠀⠀⠀⠀⡇⠀⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⡿⣿⣿⣿⣿⡿⣿⢟⣒⠶⡤⠴⡶⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⡀⠀⠀⠀⠀⠀⠀⡇⠀⠀⠀⠀⡧⡤⣴⢢⠤⠖⠔⠒⣿⣿⣿⢣⢒⡀⠀⠀⠀⠾⠀⠉⠁⠉⠉⠉⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⡀⠀⠀⠀⠀⠀⢸⠀⠀⠀⠀⠀⠉⢳⢨⡆⡇⠀⠀⠀⠿⣿⡇⠀⢏⠥⠀⠀⠀⢸⠀⠀⠀⠀⠀⠀⣷⠈⢻⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠄⠀⠀⠀⠀⠀⠘⡄⠀⠀⠀⠀⢀⣿⠘⠇⢸⠀⠀⠀⠀⠹⡇⠀⠈⢎⣥⣀⠀⠀⡆⠀⠀⠀⠀⠀⡆⠀⠀⠘⢿⣿⣿⠏⣿⣿⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠄⠀⠀⠀⠀⠀⠀⠈⠢⠤⢄⣠⣪⣾⠀⠀⢸⠀⠀⠄⠀⡇⠉⠀⠀⠈⢡⢊⡙⠀⡧⠤⠤⢀⡀⡼⠀⠀⠀⣐⠣⣿⢏⠀⣿⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⠀⢸⠀⠐⢸⠀⠀⢸⠀⡇⠀⠀⠀⠀⠈⠣⡑⢄⠸⠀⠀⠀⠠⠃⢰⡲⡞⡱⠹⠃⠈⢳⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⡄⡀⠀⠀⠀⠀⠀⠀⠀⠀⢸⢀⡠⢁⡼⢢⠇⠀⠀⠈⣆⠁⠀⠀⠀⠀⠀⠀⠈⠂⢅⠧⠀⡰⠁⢀⢔⠗⠊⠀⢠⡀⠀⠀⣇⠀⠀⠀⠀⠀
-------------------------------------------------------------
"""

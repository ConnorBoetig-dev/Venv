"""
Semantic Vector Personal Media Search
---
©AngelaMos | ©PG-VENV | Connor Boetig | Carter Perez | 2025
---
⢠⠠⢠⠔⠀⣠⠰⠌⠦⡑⢆⡒⢲⡐⢆⡒⢆⠲⡐⢎⡒⠁⠆⠄⠃⠓⠘⠆⡌⠓⢦⣌⠘⢥⣂⡈⡑⠦⣍⠛⠶⣄⡀⠀⠉⠉⠒⡄⠀⠀⠀⠀⠀⠀
⡳⢘⠀⢀⠲⠀⣡⠐⠦⡑⠎⠜⢢⠜⢢⡑⢎⡱⠑⠊⢀⠞⡀⠈⡭⡙⢭⠒⡤⢉⠒⢨⡙⠦⡀⠧⣑⠦⡙⢎⡠⠈⠈⠦⣀⠀⠀⠈⠱⣀⠀⠀⠀⠀
⠑⠀⢀⠢⠁⡜⢀⠡⡔⢠⢒⡰⠂⠊⣡⠚⡔⢢⠁⠀⣊⠖⠀⠀⢲⢉⠆⠈⠒⣩⢂⠀⠈⠱⣌⠂⠈⠒⡍⢦⡑⢎⡄⠀⠐⢣⢄⠀⠀⠀⢒⡀⠀⠀
⠀⡰⠌⠂⡘⡀⢈⠒⡬⢑⠬⠀⡰⡑⢆⢁⡎⠁⠀⠀⣇⠂⠀⠀⢈⠎⡆⠀⠀⠀⢃⠦⠀⠀⠈⢳⠀⠀⠀⠂⠹⡄⠊⡥⠀⠀⠊⡱⡈⠱⠀⠐⡀⠀
⡐⢡⠊⠐⠤⠁⢠⠩⠔⣉⠒⢠⡇⡍⢀⣾⠀⠰⠀⠀⠦⠁⠀⠀⠀⠹⣄⠀⠀⠀⠀⠀⠃⢺⡆⠀⠉⡀⠀⠀⠀⠈⠕⡈⠣⠄⠀⠀⠹⡄⠀⠀⠐⡄
⡈⢆⡁⠜⡨⠁⢠⠃⡜⠤⠁⢺⢁⡇⣾⡏⠀⠅⠀⠀⠈⡁⠀⡄⠀⠐⢌⡂⠀⢠⡀⠀⠀⠀⣴⣆⠀⠑⡀⠀⠀⠀⠀⠱⠀⠙⡀⠀⠀⠙⡆⠀⠀⠐
⡐⠢⠄⠣⢌⡡⠸⡅⠘⡜⠀⠹⣾⠧⣿⡇⠀⠎⠀⠀⠀⠁⠀⢷⡀⠀⠀⢒⡀⠘⣷⡀⠀⠀⣹⣿⣦⠀⠠⠀⠀⠀⠀⠀⠡⠀⠱⠀⠀⠀⠱⠀⠀⠀
⠰⡁⠎⡑⢢⠐⠀⡇⠘⡔⠀⢸⣏⢰⣿⠃⠀⢈⠀⠀⢀⠀⠀⠘⠿⠄⠀⠀⠐⠀⠸⣷⠀⠰⠏⠉⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠆⠀⠀
⢂⠱⡈⠔⠡⡉⠄⢹⢀⠣⠀⠀⣿⠈⣿⠀⠀⠈⠀⠀⠸⢂⠀⠀⠸⣿⣀⠀⠀⠀⠀⠻⡇⠀⠀⠸⠟⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠂⠀⠀
⠄⠣⠄⡩⠀⡑⢂⠈⢆⡡⠀⠀⠹⠄⢻⠀⠀⠀⠀⠀⠐⢿⣷⣄⠀⠹⣿⣷⣤⣀⠀⠀⠀⠀⡈⠀⠀⢸⣿⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⢈⡑⠂⡅⠀⢠⠃⠄⠈⡔⢂⠀⠀⡡⠀⡃⠀⠀⢶⣄⠀⠘⣿⣿⣷⣄⠘⢻⣿⣿⣿⣶⣦⠀⣠⡀⠀⠀⠻⣿⡇⠀⠀⢂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠠⢌⠡⡐⠀⡰⠈⠀⠀⡘⠤⠀⠀⠀⢃⠰⠀⠀⠘⢿⣦⡀⠸⣿⣿⡿⢿⠶⢭⣿⣿⣿⢃⣸⣿⣿⣤⣶⣿⣿⣧⠀⠀⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠐⢂⠡⠐⠈⢡⠀⠀⠠⠀⢣⠡⠀⠀⠁⣂⠁⠀⠀⠈⣿⣿⣂⠄⢀⣉⣉⣙⣛⣿⣿⣯⣿⣿⣿⣯⡛⣻⣿⣿⣿⠄⠀⠀⠀⠀⠀⠐⠠⢀⠀⠀⠀⠀
⠀⠠⠃⢠⢁⠂⠀⠀⠀⣁⠠⠃⠆⠀⠀⠠⢂⠀⠀⠀⠈⠿⢁⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⢀⢀⠂⠀⠀⠀⡐⠀⠀⠈⠱⡀⠀⠀⠈⢒⡀⠀⠀⠐⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⡰⢁⠂⠀⠀⠀⠐⠀⠀⠀⠀⡀⠱⡀⠀⠀⠀⠈⡱⢀⠀⠀⠙⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠟⠁⣸⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠠⠑⠀⠀⠠⠀⠀⠁⠀⠀⠀⠀⣿⠀⠔⡀⠀⠀⠀⠀⠃⢆⠹⣶⣤⣹⣿⣿⣿⣿⣿⣿⣿⣷⣶⣦⣼⣥⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠁⠀⠌⠀⠀⠄⠀⠀⠀⠀⠀⢻⣇⠀⠐⡀⠀⠀⠀⠀⠀⠒⢈⠻⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠤⠁⠀⠀⠀⠀⡄⠀⠀⠹⢦⣀⠁⠄⠀⠀⠀⠀⠀⠀⠀⠀⢬⣍⣛⣛⡛⠿⠿⠿⠿⠛⠛⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠌⠀⠄⠀⠀⠀⢠⠀⠀⠀⠀⠀⠈⠉⠀⠠⠀⠀⠀⠀⠀⠀⠀⠀⠙⠛⠛⠃⠀⠀⠀⠀⠀⠀⠀⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠠⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠰⠄⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠠⠐⡈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠂⠀⠀⠄⠀⠀⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⢂⠡⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠄⠀⠀⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠐⡈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⠀⠀⠀⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⢀⠡⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⢀⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
"""

import multiprocessing

bind = "127.0.0.1:7000"
workers = multiprocessing.cpu_count() * 2 + 1
syslog = True
proc_name = "audiencias"

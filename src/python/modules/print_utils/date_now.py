from datetime import datetime

def get_time_now():
    now = datetime.now().strftime("%d/%m/%Y %H:%M:%S")
    return now
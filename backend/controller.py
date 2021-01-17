import gspread
from oauth2client.service_account import ServiceAccountCredentials
from datetime import date
from config import Config


scope = ["https://spreadsheets.google.com/feeds",
         'https://www.googleapis.com/auth/spreadsheets',
         "https://www.googleapis.com/auth/drive.file",
         "https://www.googleapis.com/auth/drive"]

creds = ServiceAccountCredentials.from_json_keyfile_name(Config.CREDENTIAL_FILE_NAME, scope)

client = gspread.authorize(creds)
sheet = client.open(Config.SHEET_NAME).sheet1


def write_to_sheets(download_info):
    try:
        data = sheet.get_all_records()
        inserted_num = len(data) + 1

        insert_row = [inserted_num,
                      date.today().strftime('%d-%m-%Y'),
                      download_info['authors'],
                      download_info['title'],
                      download_info['year'],
                      download_info['pages_count'],
                      download_info['extension']]

        sheet.append_row(insert_row)
    except Exception as e:
        raise e

import requests
import urllib.parse
import json
from bs4 import BeautifulSoup
from datetime import datetime
from math import ceil
from multiprocessing import Pool, cpu_count
from time import sleep
from multiprocessing.dummy import Pool as ThreadPool
from flask import Flask, request, jsonify


app = Flask(__name__)

result_json = []
result_pages = []
count_page = 0

def parse(html):
    soup = BeautifulSoup(html, 'lxml')

    tables = soup.find_all('table')
    trs = tables[2].find_all('tr')[1:]
    pool = ThreadPool(len(trs))
    pool.map(parse_page, trs)
    pool.close()
    pool.join()


def parse_page(page):
    tds = page.find_all('td')

    authors = tds[1].getText()
    title = tds[2].getText()
    year = tds[4].getText()
    pages_count = tds[5].getText()
    total_size = tds[7].getText()
    extension = tds[8].getText()
    book_url = tds[9].find_all('a', href=True)[0]['href']

    result_pages.append({
        "authors": clear_string(authors),
        "title": clear_string(title),
        "year": year,
        "pages_count": pages_count,
        "total_size": total_size,
        "extension": extension,
        "url": book_url
    })


def clear_string(string):
    return ''.join([c for c in string if ord(c) < 128])


def parse_book(html):   
    soup = BeautifulSoup(html, 'lxml')
    book_image = soup.find('img')['src']
    book_name = soup.find('h1').getText()
    book_authors = soup.find_all('p')[0].getText().replace('Author(s): ','')
    book_description = soup.find_all('div')[-1].getText().replace('Description:*  ','').replace('Description:','').replace('\n', '')
    book_download_url = soup.find_all('a', href=True)[0]['href']
    result = {
        'book_image': book_image,
        'book_name': book_name,
        'book_authors': book_authors,
        'book_description': book_description,
        'book_download_url': book_download_url,
    }
    return result


def get_count_page(html):
    soup = BeautifulSoup(html, 'lxml')
    tables = soup.find_all("table")
    buf = tables[1].getText().split(' ')
    if int(buf[0]) >= 25:
        book_per_page = int(buf[9][0:2])
        count_elements = int(tables[1].getText().split(' ')[0])
        return ceil(count_elements/book_per_page)
    elif int(buf[0]) == 0:
        return 0
    return 1


def get_request(url):
    r = requests.get(url)
    while r.status_code != 200:
        try:
            r = requests.get(url)
        except:
            return get_request(url)
    return r.text


def write_to_file(total_page):
    data_to_write = []
    data_to_write.append({"total_page": total_page})
    for r in result_json:
        data_to_write.append(r)
    return data_to_write


def add_to_result():
    result_json.extend(result_pages)


def work_with_pool(url):
    html = get_request(url)
    parse(html)
    add_to_result()


def search_format(string):
    return string.replace(' ', '+')


def get_book_data(url):
    html = get_request(url)    

    buf = urllib.parse.urlparse(url)
    book_scheme = buf.scheme
    book_netloc = buf.netloc

    data = parse_book(html)
    data["book_image"] = f"{book_scheme}://{book_netloc}{data['book_image']}"
    for _, value in data.items():
        value = clear_string(value)
    return data


def get_page(query, page_num = 1):
    url = f'http://libgen.rs/search.php?&req={search_format(query)}&phrase=1&view=simple&res=25&column=def&sort=def&sortmode=ASC&page={page_num}'
    html = get_request(url)
    count_page = get_count_page(html)
    if count_page > 0:
        work_with_pool(url)
        return write_to_file(count_page)
    return {"msg": "No data"}


@app.route('/book_url', methods=['GET'])
def get_book_data_route():
    try:
        result_json.clear()
        result_pages.clear()

        book_url = request.args.get('book_url', None)
        data = get_book_data(book_url)
        return jsonify(data)
    except Exception as e:
        return {"msg": str(e)} 



@app.route('/book', methods=['GET'])
def get_books_by_name():
    try:
        result_json.clear()
        result_pages.clear()

        book_name = request.args.get('book_name', None)
        book_page = request.args.get('book_page', 1)
        data = get_page(book_name, int(book_page))
        return jsonify(data)
    except Exception as e:
        return {"msg": str(e)}



@app.route('/check', methods=['GET'])
def check_connection():
    return {"connection": True}


if __name__ == '__main__':
    app.run(debug=True)
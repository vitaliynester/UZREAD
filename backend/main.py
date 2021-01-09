import json
import urllib.parse
from datetime import datetime
from math import ceil
from multiprocessing import Pool, cpu_count
from multiprocessing.dummy import Pool as ThreadPool
from time import sleep

import requests
from bs4 import BeautifulSoup
from flask import Flask, jsonify, request
from config import Config

app = Flask(__name__)

result_json = []
result_pages = []
result_books_images = []
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
        "authors": authors,
        "title": title,
        "year": year,
        "pages_count": pages_count,
        "total_size": total_size,
        "extension": extension,
        "url": book_url
    })


def parse_book(html):   
    soup = BeautifulSoup(html, 'lxml')
    book_image = soup.find('img')['src']
    book_name = soup.find('h1').getText()
    book_authors = soup.find_all('p')[0].getText().replace('Author(s): ','')
    book_description = soup.find_all('div')[-1].getText().replace('Description:*  ','').replace('Description:','').replace('\n', '')
    book_download_url = soup.find_all('a', href=True)[1]['href']
    result = {
        'book_image': book_image,
        'book_name': book_name,
        'book_authors': book_authors,
        'book_description': book_description,
        'book_download_url': book_download_url,
    }
    return result


def get_book_download_url(uid):
    url = f"https://libgen.lc/ads.php?md5={uid}"
    html = get_request(url)
    soup = BeautifulSoup(html, 'lxml')
    book_download_url = soup.find_all('a', href=True)[0]['href']
    return book_download_url


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
        uid = book_url.split('/')[-1]
        data = get_book_data(book_url)
        #data["book_download_url"] = get_book_download_url(uid)
        return jsonify(data)
    except Exception as e:
        return {"msg": str(e)} 


def parse_book_and_image(page):
    tds = page.find_all('td')

    authors = tds[1].getText()
    title = tds[2].getText()
    year = tds[4].getText()
    pages_count = tds[5].getText()
    total_size = tds[7].getText()
    extension = tds[8].getText()
    book_url = tds[9].find_all('a', href=True)[0]['href']

    html = get_request(book_url)
    soup = BeautifulSoup(html, 'lxml')
    book_image = soup.find('img')['src']

    buf = urllib.parse.urlparse(book_url)
    book_scheme = buf.scheme
    book_netloc = buf.netloc

    result_books_images.append({
        "authors": authors,
        "title": title,
        "year": year,
        "pages_count": pages_count,
        "total_size": total_size,
        "extension": extension,
        "url": book_url,
        "image_book": f"{book_scheme}://{book_netloc}{book_image}"
    })


def work_with_pool_books_and_images(url):
    html = get_request(url)
    soup = BeautifulSoup(html, 'lxml')

    tables = soup.find_all('table')
    trs = tables[2].find_all('tr')[1:]
    pool = ThreadPool(len(trs))
    pool.map(parse_book_and_image, trs)
    pool.close()
    pool.join()


def make_response(total_page):
    data_to_write = []
    data_to_write.append({"total_page": total_page})
    for r in result_books_images:
        data_to_write.append(r)
    return data_to_write


def get_books_and_images(query, page_num = 1):
    url = f'http://libgen.rs/search.php?&req={search_format(query)}&phrase=1&view=simple&res=25&column=def&sort=def&sortmode=ASC&page={page_num}'
    html = get_request(url)
    count_page = get_count_page(html)
    if count_page > 0:
        work_with_pool_books_and_images(url)
        return make_response(count_page)
    return {"msg": "No data"}


@app.route('/v1/book', methods=['GET'])
def get_books_with_images():
    try:
        result_json.clear()
        result_pages.clear()
        result_books_images.clear()

        book_name = request.args.get('book_name', None)
        book_page = request.args.get('book_page', 1)
        data = get_books_and_images(book_name, book_page)
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


if __name__ == '__main__':
    app.run(debug=Config.DEBUG_STATUS,
            port=Config.HOST_PORT,
            host=Config.HOST_URL)

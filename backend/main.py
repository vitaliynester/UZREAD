import urllib.parse
from math import ceil
from multiprocessing.dummy import Pool as ThreadPool

import requests
from bs4 import BeautifulSoup
from flask import Flask, jsonify, request

from config import Config
import controller

app = Flask(__name__)

result_json = []
result_pages = []
result_books_images = []
count_page = 0


def parse_fragment(page):
    tds = page.find_all('td')

    authors = tds[1].getText()
    title = tds[2].getText()
    year = tds[4].getText()
    pages_count = tds[5].getText()
    total_size = tds[7].getText()
    extension = tds[8].getText()
    book_url = tds[9].find_all('a', href=True)[0]['href']

    result = {
        "authors": authors,
        "title": title,
        "year": year,
        "pages_count": pages_count,
        "total_size": total_size,
        "extension": extension,
        "url": book_url
    }
    return result


def parse_page(page):
    fragment = parse_fragment(page)
    result_pages.append(fragment)


def parse_book(html):
    soup = BeautifulSoup(html, 'lxml')
    book_image = soup.find('img')['src']
    book_name = soup.find('h1').getText()
    book_authors = soup.find_all('p')[0].getText().replace('Author(s): ', '')
    book_description = soup.find_all('div')[-1].getText().replace('Description:*  ', '')\
                                                         .replace('Description:', '')\
                                                         .replace('\n', '')
    book_download_url = soup.find_all('a', href=True)[1]['href']
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
        return ceil(count_elements / book_per_page)
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


def parse_book_and_image(page):
    fragment = parse_fragment(page)

    html = get_request(fragment['url'])
    soup = BeautifulSoup(html, 'lxml')
    book_image = soup.find('img')['src']

    buf = urllib.parse.urlparse(fragment['url'])
    book_scheme = buf.scheme
    book_netloc = buf.netloc

    result_books_images.append({
        "authors": fragment['authors'],
        "title": fragment['title'],
        "year": fragment['year'],
        "pages_count": fragment['pages_count'],
        "total_size": fragment['total_size'],
        "extension": fragment['extension'],
        "url": fragment['url'],
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


def get_books_and_images(query, page_num=1):
    url = f'http://libgen.rs/search.php?&req={search_format(query)}&phrase=1&view=simple&res=25&column=def&sort=def&sortmode=ASC&page={page_num}'
    html = get_request(url)
    count_page = get_count_page(html)
    if count_page > 0:
        work_with_pool_books_and_images(url)
        return make_response(count_page)
    return {"msg": "No data"}


def clear_temporary_arrays():
    result_json.clear()
    result_pages.clear()
    result_books_images.clear()


def get_info_from_url_book(book_url: str):
    try:
        data_from_url = get_book_data(book_url)
        get_books_and_images(data_from_url['book_name'])
        for res in result_books_images:
            if res['url'] == book_url:
                return jsonify(res)
        raise Exception('No book with that url')
    except Exception as e:
        raise e


def get_info_from_book_object(book_data, book_url):
    try:
        get_books_and_images(book_data['book_name'])
        for res in result_books_images:
            if res['url'] == book_url:
                return res
        raise Exception('No book with that url')
    except Exception as e:
        raise e


@app.route('/book_url', methods=['GET'])
def get_book_data_route():
    try:
        clear_temporary_arrays()

        book_url = request.args.get('book_url', None)
        data = get_book_data(book_url)
        download_info = get_info_from_book_object(data, book_url)
        download_info['title'] = data['book_name']
        controller.write_to_sheets(download_info)
        return jsonify(data)
    except Exception as e:
        return {"msg": str(e)}


@app.route('/v1/book', methods=['GET'])
def get_books_with_images():
    try:
        clear_temporary_arrays()

        book_name = request.args.get('book_name', None)
        book_page = request.args.get('book_page', 1)
        data = get_books_and_images(book_name, book_page)
        return jsonify(data)
    except Exception as e:
        return {"msg": str(e)}


@app.route('/v1/info_book', methods=['GET'])
def get_info_from_url_book_route():
    try:
        book_url = request.args.get('book_url', None)
        res = get_info_from_url_book(book_url)
        return res
    except Exception as e:
        return jsonify({'msg': str(e)})


if __name__ == '__main__':
    app.run(debug=Config.DEBUG_STATUS,
            port=Config.HOST_PORT,
            host=Config.HOST_URL)

import requests
from bs4 import BeautifulSoup
from datetime import datetime
import re

# URL of Scott Aaronson's blog
url = 'https://scottaaronson.blog'
headers = {
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
    'Accept-Language': 'en-DE,en;q=0.9,ar-BH;q=0.8,ar;q=0.7,de-DE;q=0.6,de;q=0.5,en-US;q=0.4',
    # Add other headers as necessary
}

def ordinal_date(dt):
    return dt.strftime("%B ") + str(dt.day) + ("th" if 4 <= dt.day % 100 <= 20 else {1: "st", 2: "nd", 3: "rd"}.get(dt.day % 10, "th")) + dt.strftime(", %Y")

def scrape_shtetl_optimized():
    response = requests.get(url, headers=headers)
    if response.status_code != 200:
        print(f"Failed to retrieve the website, status code: {response.status_code}")
        return []

    soup = BeautifulSoup(response.text, 'html.parser')
    today = ordinal_date(datetime.now())
    links = []

    # Finding the date elements
    date_elements = soup.find_all('small')
    for date_element in date_elements:
        date_text = date_element.get_text().strip()
        # Use regex to extract the date part before the comment indicator
        date_text = re.search(r'^(.*?)( <!--|$)', date_text).group(1).strip()
        if date_text == today:
            article = date_element.find_parent('div', class_='post')
            if article:
                link = article.find('a', href=True)
                if link:
                    links.append(link['href'])

    # Remove duplicates by converting to a set and back to a list
    unique_links = list(set(links))

    return unique_links
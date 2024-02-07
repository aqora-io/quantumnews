import requests
from bs4 import BeautifulSoup

MIN_SCITES = 10

def scrape_scirate():
    url = 'https://scirate.com/arxiv/quant-ph?range=7'
    headers = {
        'User-Agent': 'Mozilla/5.0',
        'Accept': 'text/html',
        # Add other headers as necessary
    }

    response = requests.get(url, headers=headers)

    # Check if the request was successful
    if response.status_code != 200:
        print("Failed to retrieve the website")
        return []

    # Parse the HTML content of the page
    soup = BeautifulSoup(response.text, 'html.parser')

    # List to store the extracted papers
    filtered_papers = []

    # Find the list of papers and process each paper
    papers_list = soup.find('ul', class_='papers')
    if papers_list:
        papers = papers_list.find_all('li', class_='paper')
        for paper in papers:
            scites_count_element = paper.find('button', class_='count')
            if scites_count_element and int(scites_count_element.text) >= MIN_SCITES:
                title_element = paper.find('div', class_='title')
                authors_element = paper.find('div', class_='authors')
                date_element = paper.find('div', class_='uid')
                abstract_element = paper.find('div', class_='abstract')

                link = title_element.find('a').get('href') if title_element else None
                authors = authors_element.get_text().strip() if authors_element else ''
                date = " ".join(date_element.get_text().strip().split()[:3]) if date_element else ''
                abstract = abstract_element.get_text().strip() if abstract_element else ''

                description = f"{authors} ({date}). \n\n**Abstract:** {abstract} \n\nArxiv: https://arxiv.org/abs/{link.split('/')[-1]}"

                if link and len(link) > 0 and not date.startswith("Jan") and int(date.split()[1]) >= 7:
                    paper_info = {
                        'link': f"https://scirate.com{link}",
                        'description': description,
                        'tags': ['pdf']
                    }
                    filtered_papers.append(paper_info)

    return filtered_papers

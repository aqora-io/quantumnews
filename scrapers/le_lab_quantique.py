import requests
import json
from datetime import datetime


def scrap_le_lab_quantique():
    url = "https://lelabquantique.com/graphql"
    headers = {
        "Content-Type": "application/json",
    }
    query = {
        "query": """
            query {
                posts {
                    nodes {
                        title,
                        link,
                        date
                    }
                }
            }
        """
    }

    response = requests.post(url, headers=headers, data=json.dumps(query))

    if response.status_code != 200:
        print("Failed to retrieve the website")
        return []

    data = response.json()
    today = datetime.now().strftime("%Y-%m-%d")
    links = [
        item["link"]
        for item in data["data"]["posts"]["nodes"]
        if "date" in item and item["date"].startswith(today) and "link" in item
    ]

    return links

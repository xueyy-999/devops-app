import zipfile
import xml.etree.ElementTree as ET
import sys

def get_docx_text(path):
    try:
        document = zipfile.ZipFile(path)
        xml_content = document.read('word/document.xml')
        document.close()
        tree = ET.XML(xml_content)
        
        text_parts = []
        
        # Define namespaces
        ns = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
        
        # Iterate over all body elements (paragraphs and tables)
        body = tree.find('w:body', ns)
        if body is None:
            return "No body found"

        for element in body:
            if element.tag == f"{{{ns['w']}}}p":
                # It's a paragraph
                texts = [node.text for node in element.iter(f"{{{ns['w']}}}t") if node.text]
                if texts:
                    text_parts.append(''.join(texts))
            elif element.tag == f"{{{ns['w']}}}tbl":
                # It's a table
                for row in element.iter(f"{{{ns['w']}}}tr"):
                    row_texts = []
                    for cell in row.iter(f"{{{ns['w']}}}tc"):
                        cell_texts = [node.text for node in cell.iter(f"{{{ns['w']}}}t") if node.text]
                        if cell_texts:
                            row_texts.append(''.join(cell_texts))
                    if row_texts:
                        text_parts.append(' | '.join(row_texts))
        
        return '\n'.join(text_parts)
    except Exception as e:
        return str(e)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python read_docx.py <filename>")
    else:
        print(get_docx_text(sys.argv[1]))

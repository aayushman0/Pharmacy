import sys, os
from docx import Document


bill_type: str = sys.argv[1]
values: List = sys.argv[2:]
document = Document("print/bill_sample.docx" if bill_type == "product" else "print/service_bill_sample.docx")
replacement_dictionary = {
	"[----]": values[0],
	"DD/MM/YYYY": values[1],
	"[Customer Name]": values[2],
	"[Bill]": "\n" + values[3],
	"[TTTTT.00]": values[4],
	"[DDDDD.00]": values[5],
	"[NNNNN.00]": values[6],
}


def replace_string(paragraph, old_string, new_string):
	inline = paragraph.runs
	for i in range(len(inline)):
		if old_string in inline[i].text:
			text = inline[i].text.replace(str(old_string), str(new_string))
			inline[i].text = text


for paragraph in document.paragraphs:
	for old_string, new_string in replacement_dictionary.items():
		if old_string in paragraph.text:
			replace_string(paragraph, old_string, new_string)
document.save("bill_output.docx")
os.startfile("bill_output.docx", "print")

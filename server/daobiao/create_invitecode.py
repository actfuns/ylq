import sys
sys.path.append('./tools/py/lib/python2.7/site-packages')
from xlutils import copy
from xlrd import open_workbook
from xlwt import easyxf
import random
import string

from datetime import datetime

INVITE_CODE_INDEX = 0
CREATE_TIME_INDEX = 1
LASTDAY_INDEX = 2
def get_random_string():
	s = string.join(random.sample(['B','C','D','E','F','G','H','I','J','K','M','N','P','Q','R','S','T','U','V','W','X','Y','2','3','4','5','6','7','8','9'],8)).replace(" ","")
	return s


def main():
	if len(sys.argv) > 1 and sys.argv[1].isdigit():
		iCodeNum=sys.argv[1]
	else:
		iCodeNum=100
	
	iCodeNum = int(iCodeNum)
	
	if len(sys.argv) > 2 and sys.argv[2].isdigit():
		iLastDay=sys.argv[2]
	else:
		iLastDay=30
	iLastDay = int(iLastDay)

	oldExcel = open_workbook('./daobiao/excel/invitecode.xls',formatting_info=1)
	oldSheet = oldExcel.sheet_by_name('invite_code')
	nrows = int(oldSheet.nrows) - 1
	newExcel=copy(oldExcel)
	newSheet = newExcel.get_sheet(0)
	now = datetime.now()
	mDict={}
	for i in range(nrows):
	    sCode = oldSheet.cell(i,0).value
	    mDict[sCode] = 1
	for i in range(iCodeNum):
	    s = get_random_string()
	    while s in mDict:
		s = get_random_string()
	    mDict[s] = 1
	    nrows = nrows + 1
	    newSheet.write(nrows,INVITE_CODE_INDEX,s)
	    newSheet.write(nrows,CREATE_TIME_INDEX,now.strftime('%Y-%m-%d %H:%M:%S'))
	    newSheet.write(nrows,LASTDAY_INDEX,iLastDay)
	newExcel.save('./daobiao/excel/invitecode.xls')
if __name__ == '__main__':
	main()


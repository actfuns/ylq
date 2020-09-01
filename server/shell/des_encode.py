#coding=utf-8
import sys
import urllib
from Crypto.Cipher import DES

class MyDESCrypt:
    def __init__(self):
        self.key = '!~btusd.'
        self.iv = '!~btusd.'

    def ecrypt(self,ecryptText):
       try:
           ecryptText = urllib.quote(ecryptText).lower()
           cipherX = DES.new(self.key, DES.MODE_CBC, self.iv)
           pad = 8 - len(ecryptText) % 8
           padStr = ""
           for i in range(pad):
              padStr = padStr + chr(pad)
           ecryptText = ecryptText + padStr
           x = cipherX.encrypt(ecryptText)
           return x.encode('hex_codec').upper()
       except:
           return ""


    def decrypt(self,decryptText):
        try:
            cipherX = DES.new(self.key, DES.MODE_CBC, self.iv)
            str = decryptText.decode('hex_codec')
            y = cipherX.decrypt(str)
            return y[0:ord(y[len(y)-1])*-1]
        except:
            return ""

if __name__ == "__main__":
    if len(sys.argv) == 2:
        text = sys.argv[1]
        mydes = MyDESCrypt()
        print mydes.ecrypt(text),
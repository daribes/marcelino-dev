#!/usr/bin/env python

import sys
import os

#guarda conocimeintos en los archivos indicados
fp = open('saludo.pl','a')
fp.write("saludo(hola,\'que tal\').\n")
fp.close()

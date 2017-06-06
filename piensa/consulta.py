#!/usr/bin/env python

from pyswip import Prolog
import sys
import os
from random import randint

#inicializamos prolog con pyswip
prolog = Prolog()

#adquirimos las bases de conocimientos relacionadas en el archivo asimila.con
ruta = os.getcwd()
fr = open('asimila.con','r')
for a_concepto in fr.xreadlines():
    prolog.consult(ruta+'/'+a_concepto[:len(a_concepto)-1])
fr.close()

#prueba para ver si funciona una consulta pasada por parametro
try:
    if sys.argv[1] != '':
        try:
            if sys.argv[2] != '':
                pregunta = sys.argv[1]+'('+sys.argv[2]+',X)'
            else:
                pregunta = sysargv[1]
            prueba = list(prolog.query(pregunta))
            print(prueba[randint(0,len(prueba)-1)]["X"])
            try:
                prueba1 = list(prolog.query(prueba[randint(0,len(prueba)-1)]["X"]+'('+sys.argv[2]+',X)'))
                if len(prueba1) > 1:
                    print(prueba1[randint(0,len(prueba1)-1)]["X"])
            except:
                pass
        except:
            print 'NOSE'
except IndexError:
    print 'Nada que consultar'

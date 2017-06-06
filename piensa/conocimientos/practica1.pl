progenitor(david,maria).
progenitor(maria,juan).
abuelo(X,Y) :- progenitor(X,Z), progenitor(Z,Y).

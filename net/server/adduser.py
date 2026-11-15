"""Aggiunge o cambia un utente del server: python adduser.py <nome (max 11)> <chiave (max 15)>
(il nome e la chiave si digitano poi nelle impostazioni di rete del gioco, tasto N)."""
import json
import os
import sys

store = os.path.join(os.path.dirname(os.path.abspath(__file__)), "store")
path = os.path.join(store, "users.json")
if len(sys.argv) != 3 or len(sys.argv[1]) > 11 or len(sys.argv[2]) > 15:
    sys.exit(__doc__)
os.makedirs(store, exist_ok=True)
users = json.load(open(path)) if os.path.exists(path) else {}
users[sys.argv[1]] = sys.argv[2]
json.dump(users, open(path, "w"), indent=1)
print("utente '%s' salvato (%d utenti)" % (sys.argv[1], len(users)))

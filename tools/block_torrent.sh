#!/bin/bash

    sudo ufw deny from any to any proto any string "BitTorrent" comment "Blocking BitTorrent"
   sudo ufw deny from any to any proto any string "BitTorrent protocol" comment "Blocking BitTorrent protocol"
   sudo ufw deny from any to any proto any string "peer_id=" comment "Blocking peer_id="
   sudo ufw deny from any to any proto any string ".torrent" comment "Blocking .torrent"
   sudo ufw deny from any to any proto any string "announce.php?passkey=" comment "Blocking announce.php?passkey="
   sudo ufw deny from any to any proto any string "torrent" comment "Blocking torrent"
   sudo ufw deny from any to any proto any string "announce" comment "Blocking announce"
   sudo ufw deny from any to any proto any string "info_hash" comment "Blocking info_hash"

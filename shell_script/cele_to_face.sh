#!/bin/bash
if [ $# -eq 0 ]
then
	echo "No arguments supplied"
else
	echo "scanning on "$3" for "$1" with stride "$2"pix."
	rm -rf /home/lichao/smaller/vault/caltech_sepa/single_face/${3}_head_cele_${2}pix_bywords_3/$1/
	mkdir -p /home/lichao/smaller/vault/caltech_sepa/single_face/${3}_head_cele_${2}pix_bywords_3/$1/
	ruby ../process_rect.rb if draw_group_quality /home/lichao/smaller/vault/cele2017/${3}_head_cele_${2}pix_bywords_3/$1/ /home/lichao/smaller/vault/caltech_sepa/single_face/${3}_head_cele_${2}pix_bywords_3/$1/ /home/lichao/smaller/vault/cele2017/scan_${3}_head_cele_${2}pix_bywords_3_$1.txt /home/lichao/smaller/vault/caltech_sepa/single_face/kmeans_800_64.txt nil /home/lichao/smaller/vault/caltech_sepa/single_face/net2_raw.txt /home/lichao/smaller/vault/caltech_sepa/single_face/net2_el.txt /home/lichao/smaller/vault/caltech_sepa/single_face/global_summary.txt /home/lichao/smaller/vault/caltech_sepa/single_face/voro_centers.txt
fi

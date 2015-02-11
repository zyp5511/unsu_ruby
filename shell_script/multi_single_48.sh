#!/bin/bash
pushd /home/lichao/scratch/pami
rm -r motor_res motor_face motor_car motor_airplane
mkdir motor_res motor_face motor_car motor_airplane
popd

ruby process_rect.rb if draw_group_quality /home/lichao/scratch/pami/data/car_test/ /home/lichao/scratch/pami/motor_car/ /home/lichao/scratch/pami/quad_train_car.txt /home/lichao/scratch/pami/quad_kmeans_800.txt nil /home/lichao/scratch/pami/quad_train_net2_raw.txt /home/lichao/scratch/pami/quad_train_net2_el.txt /home/lichao/scratch/pami/quad_train_global_summary.txt /home/lichao/scratch/pami/quad_train_voro_centers.txt|tee multi_car.txt
ruby process_rect.rb if draw_group_quality /home/lichao/scratch/pami/data/airplane_test/ /home/lichao/scratch/pami/motor_airplane/ /home/lichao/scratch/pami/quad_train_airplane.txt /home/lichao/scratch/pami/quad_kmeans_800.txt nil /home/lichao/scratch/pami/quad_train_net2_raw.txt /home/lichao/scratch/pami/quad_train_net2_el.txt /home/lichao/scratch/pami/quad_train_global_summary.txt /home/lichao/scratch/pami/quad_train_voro_centers.txt|tee multi_airplane.txt
ruby process_rect.rb if draw_group_quality /home/lichao/scratch/pami/data/face_test/ /home/lichao/scratch/pami/motor_face/ /home/lichao/scratch/pami/quad_train_face.txt /home/lichao/scratch/pami/quad_kmeans_800.txt nil /home/lichao/scratch/pami/quad_train_net2_raw.txt /home/lichao/scratch/pami/quad_train_net2_el.txt /home/lichao/scratch/pami/quad_train_global_summary.txt /home/lichao/scratch/pami/quad_train_voro_centers.txt|tee multi_face.txt
ruby process_rect.rb if draw_group_quality /home/lichao/scratch/pami/data/motorbike_test/ /home/lichao/scratch/pami/motor_res/ /home/lichao/scratch/pami/quad_test_res.txt /home/lichao/scratch/pami/quad_kmeans_800.txt nil /home/lichao/scratch/pami/quad_train_net2_raw.txt /home/lichao/scratch/pami/quad_train_net2_el.txt /home/lichao/scratch/pami/quad_train_global_summary.txt /home/lichao/scratch/pami/quad_train_voro_centers.txt|tee multi_motorbike.txt

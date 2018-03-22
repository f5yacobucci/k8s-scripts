#!/bin/bash

set -e

for i in 0 1 2 3 4 5
do
  kubectl delete service test-$i
  kubectl delete deployment test-$i
  kubectl delete ingress test-$i
 done

#for i in bar.example.com baz.example.com corge.example.com qux.example.com foo.example.com thud.example.com
#do
#  kubectl delete secret $i
#done

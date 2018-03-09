#!/bin/bash

set -e

for i in 0 1 2 3 4 5
do
  kubectl delete service nginx-$i
  kubectl delete deployment nginx-$i
  kubectl delete ingress nginx-$i
 done

for i in bar.example.com baz.example.com corge.example.com qux.example.com foo.example.com thud.example.com
do
  kubectl delete secret $i
done

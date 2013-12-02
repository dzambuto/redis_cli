redis.dart
==========

tiny redis client for dart

# Benchmark
RedisProtocolParser (standard) - 5 clients - {TCPNODELAY=true}

        PING,        1/5,          0/         9/      0.10        2084ms,       9596 ops/s
        PING,       50/5,          0/         3/      0.53         211ms,      94786 ops/s
        PING,      200/5,          0/         4/      1.69         169ms,     118343 ops/s
        PING,    20000/5,         44/       173/    108.56         175ms,     114285 ops/s
  SET small str,         1/5,          0/        21/      0.10        1951ms,      10251 ops/s
  SET small str,        50/5,          0/         5/      0.56         226ms,      88495 ops/s
  SET small str,       200/5,          0/        15/      2.11         211ms,      94786 ops/s
  SET small str,     20000/5,         40/       202/    123.16         205ms,      97560 ops/s
  GET small str,         1/5,          0/        19/      0.11        2156ms,       9276 ops/s
  GET small str,        50/5,          0/         7/      0.59         236ms,      84745 ops/s
  GET small str,       200/5,          0/        16/      2.18         218ms,      91743 ops/s
  GET small str,     20000/5,         52/       223/    141.37         225ms,      88888 ops/s
  SET large str,         1/5,          0/         9/      0.25        5128ms,       3900 ops/s
  SET large str,        50/5,          0/        18/     10.18        4078ms,       4903 ops/s
  SET large str,       200/5,          0/        73/     40.35        4054ms,       4932 ops/s
  SET large str,     20000/5,         19/      3903/   1946.76        3907ms,       5119 ops/s
  GET large str,         1/5,          0/        19/      0.51       10304ms,       1940 ops/s
  GET large str,        50/5,          7/        59/     20.87        8355ms,       2393 ops/s
  GET large str,       200/5,         29/       200/     83.96        8410ms,       2378 ops/s
  GET large str,     20000/5,        139/      8141/   4576.15        8238ms,       2427 ops/s
        INCR,        1/5,          0/        10/      0.10        2155ms,       9280 ops/s
        INCR,       50/5,          0/         6/      0.55         219ms,      91324 ops/s
        INCR,      200/5,          0/         8/      1.92         193ms,     103626 ops/s
        INCR,    20000/5,         18/       199/    116.62         201ms,      99502 ops/s
       LPUSH,        1/5,          0/         8/      0.10        2023ms,       9886 ops/s
       LPUSH,       50/5,          0/         5/      0.61         246ms,      81300 ops/s
       LPUSH,      200/5,          0/         8/      2.14         214ms,      93457 ops/s
       LPUSH,    20000/5,         31/       206/    122.36         209ms,      95693 ops/s
   LRANGE 10,        1/5,          0/         7/      0.13        2732ms,       7320 ops/s
   LRANGE 10,       50/5,          0/         6/      1.25         500ms,      40000 ops/s
   LRANGE 10,      200/5,          1/        10/      4.43         444ms,      45045 ops/s
   LRANGE 10,    20000/5,        229/       381/    309.34         432ms,      46296 ops/s
  LRANGE 100,        1/5,          0/         6/      0.34        6897ms,       2899 ops/s
  LRANGE 100,       50/5,          1/       108/      6.59        2638ms,       7581 ops/s
  LRANGE 100,      200/5,          8/       113/     27.43        2748ms,       7278 ops/s
  LRANGE 100,    20000/5,        290/      2616/   1657.51        2684ms,       7451 ops/s
  End of Test.

RedisProtocolParser (standard) - 5 clients - {TCPNODELAY=false}

        PING,        1/5,          0/         9/      0.09        1892ms,      10570 ops/s
        PING,       50/5,          0/         9/      0.54         218ms,      91743 ops/s
        PING,      200/5,          0/         4/      1.55         155ms,     129032 ops/s
        PING,    20000/5,         37/       135/     79.59         137ms,     145985 ops/s
  SET small str,         1/5,          0/         9/      0.10        2144ms,       9328 ops/s
  SET small str,        50/5,          0/         5/      0.58         232ms,      86206 ops/s
  SET small str,       200/5,          0/        15/      2.12         213ms,      93896 ops/s
  SET small str,     20000/5,         13/       174/     98.22         176ms,     113636 ops/s
  GET small str,         1/5,          0/         7/      0.11        2186ms,       9149 ops/s
  GET small str,        50/5,          0/        15/      0.63         253ms,      79051 ops/s
  GET small str,       200/5,          0/         8/      2.13         214ms,      93457 ops/s
  GET small str,     20000/5,         61/       175/    124.19         177ms,     112994 ops/s
  SET large str,         1/5,          0/        52/     39.98      799881ms,         25 ops/s
  SET large str,        50/5,          2/        40/      7.77        3137ms,       6375 ops/s
  SET large str,       200/5,          4/        60/     30.24        3069ms,       6516 ops/s
  SET large str,     20000/5,         19/      2980/   1498.07        2993ms,       6682 ops/s
  GET large str,         1/5,          0/        18/      0.56       11222ms,       1782 ops/s
  GET large str,        50/5,          9/        56/     20.58        8238ms,       2427 ops/s
  GET large str,       200/5,         23/       184/     83.43        8359ms,       2392 ops/s
  GET large str,     20000/5,        146/      7999/   4522.55        8076ms,       2476 ops/s
        INCR,        1/5,          0/         6/      0.10        2063ms,       9694 ops/s
        INCR,       50/5,          0/         7/      0.53         212ms,      94339 ops/s
        INCR,      200/5,          0/        10/      1.93         193ms,     103626 ops/s
        INCR,    20000/5,         35/       145/     85.78         147ms,     136054 ops/s
       LPUSH,        1/5,          0/        69/      0.11        2222ms,       9000 ops/s
       LPUSH,       50/5,          0/         5/      0.63         255ms,      78431 ops/s
       LPUSH,      200/5,          0/         8/      2.15         216ms,      92592 ops/s
       LPUSH,    20000/5,         18/       159/     93.22         162ms,     123456 ops/s
   LRANGE 10,        1/5,          0/        11/      0.13        2722ms,       7347 ops/s
   LRANGE 10,       50/5,          0/         5/      1.11         446ms,      44843 ops/s
   LRANGE 10,      200/5,          2/        10/      3.85         387ms,      51679 ops/s
   LRANGE 10,    20000/5,        180/       309/    246.82         382ms,      52356 ops/s
  LRANGE 100,        1/5,          0/        52/      0.34        6818ms,       2933 ops/s
  LRANGE 100,       50/5,          1/        79/      7.37        2951ms,       6777 ops/s
  LRANGE 100,      200/5,          4/       115/     25.59        2563ms,       7803 ops/s
  LRANGE 100,    20000/5,        155/      2772/   1737.16        2841ms,       7039 ops/s

  
RedisProtocolParser (mranney parser porting) - 5 clients - {TCP_NODELAY=true, new_gen_heap_size=1024}

        PING,        1/5,          0/         9/      0.09        1836ms,      10893 ops/s
        PING,       50/5,          0/         9/      0.57         229ms,      87336 ops/s
        PING,      200/5,          0/         4/      1.81         181ms,     110497 ops/s
        PING,    20000/5,         23/       160/     91.90         164ms,     121951 ops/s
  SET small str,         1/5,          0/         2/      0.10        2088ms,       9578 ops/s
  SET small str,        50/5,          0/         3/      0.61         246ms,      81300 ops/s
  SET small str,       200/5,          0/         4/      2.12         212ms,      94339 ops/s
  SET small str,     20000/5,         20/       186/    103.60         190ms,     105263 ops/s
  GET small str,         1/5,          0/         3/      0.10        2013ms,       9935 ops/s
  GET small str,        50/5,          0/         2/      0.58         234ms,      85470 ops/s
  GET small str,       200/5,          0/         4/      2.11         211ms,      94786 ops/s
  GET small str,     20000/5,         32/       186/    109.18         190ms,     105263 ops/s
  SET large str,         1/5,          0/        19/      0.27        5357ms,       3733 ops/s
  SET large str,        50/5,          0/        28/      9.93        3976ms,       5030 ops/s
  SET large str,       200/5,          1/        83/     40.39        4058ms,       4928 ops/s
  SET large str,     20000/5,         15/      3907/   1963.63        3911ms,       5113 ops/s
  GET large str,         1/5,          0/        69/      0.36        7190ms,       2781 ops/s
  GET large str,        50/5,          5/       176/     12.07        4830ms,       4140 ops/s
  GET large str,       200/5,         13/       243/     53.25        5337ms,       3747 ops/s
  GET large str,     20000/5,         93/      6341/   3568.40        6409ms,       3120 ops/s
        INCR,        1/5,          0/         4/      0.10        2152ms,       9293 ops/s
        INCR,       50/5,          0/         2/      0.52         209ms,      95693 ops/s
        INCR,      200/5,          0/       102/      2.88         288ms,      69444 ops/s
        INCR,    20000/5,         22/       167/     95.78         171ms,     116959 ops/s
       LPUSH,        1/5,          0/         5/      0.10        2094ms,       9551 ops/s
       LPUSH,       50/5,          0/         2/      0.57         229ms,      87336 ops/s
       LPUSH,      200/5,          0/         5/      2.09         210ms,      95238 ops/s
       LPUSH,    20000/5,         23/       179/    102.03         183ms,     109289 ops/s
   LRANGE 10,        1/5,          0/         5/      0.13        2616ms,       7645 ops/s
   LRANGE 10,       50/5,          0/       191/      1.52         607ms,      32948 ops/s
   LRANGE 10,      200/5,          1/         9/      3.87         388ms,      51546 ops/s
   LRANGE 10,    20000/5,        178/       298/    234.96         354ms,      56497 ops/s
  LRANGE 100,        1/5,          0/       100/      0.29        5836ms,       3427 ops/s
  LRANGE 100,       50/5,          1/       168/      5.74        2297ms,       8707 ops/s
  LRANGE 100,      200/5,          4/       192/     22.44        2248ms,       8896 ops/s
  LRANGE 100,    20000/5,        157/      2170/   1452.46        2248ms,       8896 ops/s
  End of Test.
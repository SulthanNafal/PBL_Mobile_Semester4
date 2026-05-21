import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_event_page.dart';
import 'admin_profile_page.dart';

class DashboardAdmin extends StatefulWidget {
  const DashboardAdmin({super.key});

  @override
  State<DashboardAdmin> createState() => _DashboardAdminState();
}

class _DashboardAdminState extends State<DashboardAdmin> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const AdminHomePage(),
    const AdminEventPage(),
    const AdminProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFFD32F2F),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_outlined),
            activeIcon: Icon(Icons.event),
            label: 'Event',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getTopTickets() async {

    final transaksi = await supabase
        .schema('ursaevent')
        .from('transaksis')
        .select('id_tiket,status')
        .eq('status', 'aktif');

    Map<int, int> jumlahTiket = {};

    for (var item in transaksi) {

      int id = item['id_tiket'];

      jumlahTiket[id] =
          (jumlahTiket[id] ?? 0) + 1;
    }

    List<Map<String, dynamic>> hasil = [];

    for (var item in jumlahTiket.entries) {

      final tiket = await supabase
          .schema('ursaevent')
          .from('tikets')
          .select('nama_tiket,kategori')
          .eq('id', item.key)
          .single();

      hasil.add({
        "nama": tiket['nama_tiket'],
        "kategori": tiket['kategori'],
        "jumlah": item.value,
      });
    }

    hasil.sort(
          (a,b)=> b['jumlah']
          .compareTo(a['jumlah']),
    );

    return hasil.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFD32F2F),
        title: const Text(
          "Dashboard Admin",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: FutureBuilder<List<Map<String,dynamic>>>(
        future: getTopTickets(),

        builder: (context,snapshot){

          if(snapshot.connectionState ==
              ConnectionState.waiting){

            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if(snapshot.hasError){

            return Center(
              child: Text(
                "Error : ${snapshot.error}",
              ),
            );
          }

          final data =
              snapshot.data ?? [];

          if(data.isEmpty){

            return const Center(
              child: Text(
                "Belum ada data tiket terjual",
              ),
            );
          }

          double maxValue =
          data.first['jumlah']
              .toDouble();

          return SingleChildScrollView(

            padding:
            const EdgeInsets.all(20),

            child: Column(

              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                const Text(
                  "Top 5 Tiket Terlaris",
                  style: TextStyle(
                    fontSize:24,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height:20,
                ),

                ...data.asMap().entries.map((e){

                  int index=e.key;
                  var item=e.value;

                  double value =
                  item['jumlah']
                      .toDouble();

                  return Card(

                    elevation:5,

                    margin:
                    const EdgeInsets.only(
                      bottom:15,
                    ),

                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                          15
                      ),
                    ),

                    child: Padding(

                      padding:
                      const EdgeInsets.all(16),

                      child: Column(

                        crossAxisAlignment:
                        CrossAxisAlignment.start,

                        children: [

                          Row(

                            mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,

                            children: [

                              Text(
                                "Terlaris #${index+1}",
                                style:
                                const TextStyle(
                                  fontWeight:
                                  FontWeight.bold,
                                  fontSize:16,
                                ),
                              ),

                              Text(
                                "${item['jumlah']} terjual",
                                style:
                                const TextStyle(
                                  fontSize:14,
                                ),
                              )
                            ],
                          ),

                          const SizedBox(
                            height:10,
                          ),

                          Text(
                            item['nama'],
                            style:
                            const TextStyle(
                              fontSize:18,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),

                          const SizedBox(
                            height:6,
                          ),

                          Container(

                            padding:
                            const EdgeInsets.symmetric(
                              horizontal:10,
                              vertical:5,
                            ),

                            decoration:
                            BoxDecoration(
                              color:
                              Colors.red
                                  .shade50,

                              borderRadius:
                              BorderRadius
                                  .circular(
                                  20
                              ),
                            ),

                            child: Text(
                              "Kategori : ${item['kategori']}",
                              style:
                              const TextStyle(
                                color:
                                Colors.red,
                                fontWeight:
                                FontWeight.w500,
                              ),
                            ),
                          ),

                          const SizedBox(
                            height:15,
                          ),

                          LinearProgressIndicator(

                            value:
                            value /
                                maxValue,

                            minHeight:18,

                            borderRadius:
                            BorderRadius.circular(
                                20
                            ),

                            backgroundColor:
                            Colors.grey
                                .shade300,

                            valueColor:
                            const AlwaysStoppedAnimation(
                              Color(
                                  0xFFD32F2F
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );

                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}
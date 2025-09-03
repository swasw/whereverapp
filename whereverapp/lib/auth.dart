import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:whereverapp/main.dart';

class Supabase {
  Future<void> addPos() async {
    debugPrint("addddddddd");
    await supabase.from('maps').insert({'lat': 3.20349, 'lng': 1.2342});
  }

  Future<List> getPos() async {
    debugPrint("getsss");
    final data = await supabase.from('maps').select();
    debugPrint(data.toString());
    debugPrint("printed");
    debugPrint(data[0]['lat'].toString() + " " + data[0]['lng'].toString());
    return data;
  }

  Future<List> getPosbyId(int id) async {
    debugPrint("getsss");
    final data = await supabase.from('maps').select().eq("id", id);
    debugPrint(data.toString());
    debugPrint("printed");
    debugPrint(data[0]['lat'].toString() + " " + data[0]['lng'].toString());
    return data;
  }

  Future<void> updatePos(int id, double lat, double lng) async {
    await supabase.from('instruments').update({'name': 'piano'}).eq('id', id);
  }

  Future<void> deletePos() async {
    final data = await supabase.from('instruments').upsert({
      'id': 1,
      'name': 'piano',
    }).select();
  }
}

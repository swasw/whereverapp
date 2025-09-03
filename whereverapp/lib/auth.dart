import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:whereverapp/main.dart';

class Supabase {
  Future<void> addPos(double lat, double lng, String name) async {
    debugPrint("addddddddd");

    final data = await supabase.from('maps').select().eq("name", name);
    if (data.isEmpty) {
      await supabase.from('maps').insert({
        'lat': lat,
        'lng': lng,
        'name': name,
      });
    } else {
      await supabase
          .from('maps')
          .update({
            'lat': lat,
            'lng': lng,
            'updated_at': DateTime.now().toString(),
          })
          .eq("name", name);
    }
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

  Future<void> updatePos(String name, double lat, double lng) async {
    await supabase
        .from('maps')
        .update({
          'lat': lat,
          'lng': lng,
          'updated_at': DateTime.now().toString(),
        })
        .eq("name", name);
  }

  Future<void> deletePos() async {
    final data = await supabase.from('instruments').upsert({
      'id': 1,
      'name': 'piano',
    }).select();
  }
}

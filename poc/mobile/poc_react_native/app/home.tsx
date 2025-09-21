import React from "react";
import { View, Text, Button, Alert } from "react-native";
import { useRouter } from "expo-router";
import { useAuth } from "@/state/auth";

export default function HomeScreen() {
  const router = useRouter();
  const { user, tokens, logout } = useAuth();

  const onLogout = async () => {
    try {
      await logout();
      router.replace("/login");
    } catch (e: unknown) {
      Alert.alert("Logout error", e instanceof Error ? e.message : String(e));
    }
  };

  return (
    <View style={{ flex:1, alignItems:"center", justifyContent:"center", padding:16 }}>
      <View style={{ width:"100%", maxWidth:420, backgroundColor:"#fff", padding:16, borderRadius:12 }}>
        <Text style={{ fontSize:22, fontWeight:"600", marginBottom:12 }}>Home</Text>
        <Text>User: {user?.email ?? "—"}</Text>

        <Text style={{ marginTop:12, fontWeight:"600" }}>Access token:</Text>
        <Text selectable>{tokens.access_token ?? "—"}</Text>

        <Text style={{ marginTop:12, fontWeight:"600" }}>Refresh token:</Text>
        <Text selectable>{tokens.refresh_token ?? "—"}</Text>

        <View style={{ height:16 }} />
        <Button title="Logout" onPress={onLogout} />
      </View>
    </View>
  );
}

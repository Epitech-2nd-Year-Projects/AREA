import React, { useState } from "react";
import { View, Text, TextInput, Button, Alert } from "react-native";
import { useRouter } from "expo-router";
import { useAuth } from "@/state/auth";

export default function RegisterScreen() {
  const router = useRouter();
  const { register } = useAuth();
  const [email, setEmail] = useState<string>("");
  const [password, setPassword] = useState<string>("");

  const onRegister = async () => {
    try {
      await register(email, password);
      Alert.alert("OK", "Account created");
      router.back();
    } catch (e: unknown) {
      Alert.alert("Register failed", e instanceof Error ? e.message : String(e));
    }
  };

  return (
    <View style={{ flex:1, alignItems:"center", justifyContent:"center", padding:16 }}>
      <View style={{ width:"100%", maxWidth:420, backgroundColor:"#fff", padding:16, borderRadius:12 }}>
        <Text style={{ fontSize:22, fontWeight:"600", marginBottom:12 }}>Register</Text>

        <Text>Email</Text>
        <TextInput
          value={email}
          onChangeText={setEmail}
          autoCapitalize="none"
          keyboardType="email-address"
          style={{ borderWidth:1, borderRadius:8, padding:10, marginTop:6, marginBottom:12 }}
        />

        <Text>Password</Text>
        <TextInput
          value={password}
          onChangeText={setPassword}
          secureTextEntry
          style={{ borderWidth:1, borderRadius:8, padding:10, marginTop:6, marginBottom:16 }}
        />

        <Button title="Create account" onPress={onRegister} />
      </View>
    </View>
  );
}

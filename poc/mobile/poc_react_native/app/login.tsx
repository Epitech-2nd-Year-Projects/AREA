import React, { useState } from "react";
import { View, Text, TextInput, Button, Alert } from "react-native";
import { useRouter } from "expo-router";
import { useAuth } from "../state/auth";

export default function LoginScreen() {
  const router = useRouter();
  const { login } = useAuth();
  const [email, setEmail] = useState<string>("test@example.com");
  const [password, setPassword] = useState<string>("password");

  const onLogin = async () => {
    try {
      await login(email, password);
      router.replace("/home");
    } catch (e: unknown) {
      Alert.alert("Login failed", e instanceof Error ? e.message : String(e));
    }
  };

  return (
    <View style={{ flex: 1, alignItems: "center", justifyContent: "center", padding: 16 }}>
      <View style={{ width: "100%", maxWidth: 420, backgroundColor: "#fff", padding: 16, borderRadius: 12 }}>
        <Text style={{ fontSize: 22, fontWeight: "600", marginBottom: 12 }}>Login (POC)</Text>

        <Text>Email</Text>
        <TextInput
          value={email}
          onChangeText={setEmail}
          autoCapitalize="none"
          keyboardType="email-address"
          style={{ borderWidth: 1, borderRadius: 8, padding: 10, marginTop: 6, marginBottom: 12 }}
        />

        <Text>Password</Text>
        <TextInput
          value={password}
          onChangeText={setPassword}
          secureTextEntry
          style={{ borderWidth: 1, borderRadius: 8, padding: 10, marginTop: 6, marginBottom: 16 }}
        />

        <Button title="Login" onPress={onLogin} />
        <View style={{ height: 8 }} />
        <Button title="No account? Register" onPress={() => router.push("/register")} />
      </View>
    </View>
  );
}

import React from "react";
import { Redirect } from "expo-router";
import { useAuth } from "@/state/auth";

export default function Index() {
  const { user } = useAuth();
  return <Redirect href={user ? "/home" : "/login"} />;
}

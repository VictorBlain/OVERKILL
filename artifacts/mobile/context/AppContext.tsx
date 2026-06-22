import AsyncStorage from "@react-native-async-storage/async-storage";
import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useState,
} from "react";
import { FUNCTION_COLORS } from "@/constants/colors";

export interface GraphFunction {
  id: string;
  expression: string;
  color: string;
  visible: boolean;
}

interface AppContextType {
  functions: GraphFunction[];
  addFunction: (expression: string) => void;
  removeFunction: (id: string) => void;
  toggleFunction: (id: string) => void;
  updateFunction: (id: string, expression: string) => void;
  history: string[];
  addToHistory: (entry: string) => void;
}

const AppContext = createContext<AppContextType | null>(null);

const STORAGE_KEY = "@overkill_functions";

export function AppProvider({ children }: { children: React.ReactNode }) {
  const [functions, setFunctions] = useState<GraphFunction[]>([
    {
      id: "1",
      expression: "x^2",
      color: FUNCTION_COLORS[0],
      visible: true,
    },
  ]);
  const [history, setHistory] = useState<string[]>([]);

  useEffect(() => {
    AsyncStorage.getItem(STORAGE_KEY).then((data) => {
      if (data) {
        try {
          setFunctions(JSON.parse(data));
        } catch {}
      }
    });
  }, []);

  useEffect(() => {
    AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(functions));
  }, [functions]);

  const addFunction = useCallback((expression: string) => {
    setFunctions((prev) => {
      const colorIdx = prev.length % FUNCTION_COLORS.length;
      return [
        ...prev,
        {
          id: Date.now().toString(),
          expression,
          color: FUNCTION_COLORS[colorIdx],
          visible: true,
        },
      ];
    });
  }, []);

  const removeFunction = useCallback((id: string) => {
    setFunctions((prev) => prev.filter((f) => f.id !== id));
  }, []);

  const toggleFunction = useCallback((id: string) => {
    setFunctions((prev) =>
      prev.map((f) => (f.id === id ? { ...f, visible: !f.visible } : f))
    );
  }, []);

  const updateFunction = useCallback((id: string, expression: string) => {
    setFunctions((prev) =>
      prev.map((f) => (f.id === id ? { ...f, expression } : f))
    );
  }, []);

  const addToHistory = useCallback((entry: string) => {
    setHistory((prev) => [entry, ...prev.slice(0, 49)]);
  }, []);

  return (
    <AppContext.Provider
      value={{
        functions,
        addFunction,
        removeFunction,
        toggleFunction,
        updateFunction,
        history,
        addToHistory,
      }}
    >
      {children}
    </AppContext.Provider>
  );
}

export function useApp() {
  const ctx = useContext(AppContext);
  if (!ctx) throw new Error("useApp must be used within AppProvider");
  return ctx;
}

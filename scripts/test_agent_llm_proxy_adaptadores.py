#!/usr/bin/env python3
"""Pruebas para los adaptadores adapt_mistral y adapt_groq en agent_llm_proxy.py."""

import copy
import unittest

from scripts.agent_llm_proxy import GROQ_MAX_TOKENS, adapt_groq, adapt_mistral


class TestAdaptMistral(unittest.TestCase):
    def test_top_level_whitelist_and_dropped(self):
        body = {
            "model": "mistral-large-latest",
            "temperature": 0.7,
            "extra_top_field": "disallowed",
        }
        body_original = copy.deepcopy(body)
        dropped = set()

        result = adapt_mistral(body, dropped)

        self.assertEqual(body, body_original)
        self.assertNotIn("extra_top_field", result)
        self.assertEqual(result["model"], "mistral-large-latest")
        self.assertEqual(result["temperature"], 0.7)
        self.assertIn("body.extra_top_field", dropped)

    def test_renaming_max_completion_tokens_and_seed(self):
        body = {
            "model": "mistral-small-latest",
            "max_completion_tokens": 1500,
            "seed": 2026,
        }
        dropped = set()

        result = adapt_mistral(body, dropped)

        self.assertEqual(result["max_tokens"], 1500)
        self.assertEqual(result["random_seed"], 2026)
        self.assertNotIn("body.max_completion_tokens", dropped)
        self.assertNotIn("body.seed", dropped)

    def test_cleaning_messages_and_roles(self):
        body = {
            "model": "mistral-large-latest",
            "messages": [
                {
                    "role": "system",
                    "content": "Eres un asistente.",
                    "extra_system_key": "bad",
                },
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": "Hola", "extra_part_key": "bad"},
                    ],
                    "extra_user_key": "bad",
                },
                {
                    "role": "assistant",
                    "content": None,
                    "tool_calls": [
                        {
                            "id": "long_tool_call_id_12345",
                            "type": "function",
                            "function": {
                                "name": "search",
                                "arguments": "{}",
                                "extra_func_key": "bad",
                            },
                            "extra_tc_key": "bad",
                        }
                    ],
                    "extra_assistant_key": "bad",
                },
                {
                    "role": "tool",
                    "content": "resultado",
                    "tool_call_id": "long_tool_call_id_12345",
                    "name": "search",
                    "extra_tool_msg_key": "bad",
                },
            ],
        }
        body_original = copy.deepcopy(body)
        dropped = set()

        result = adapt_mistral(body, dropped)

        self.assertEqual(body, body_original)
        messages = result["messages"]

        # Check system message
        self.assertEqual(messages[0], {"role": "system", "content": "Eres un asistente."})

        # Check user message content part
        self.assertEqual(messages[1]["role"], "user")
        self.assertEqual(messages[1]["content"], [{"type": "text", "text": "Hola"}])

        # Check assistant message content None converted to "" and tool call ID normalized
        self.assertEqual(messages[2]["role"], "assistant")
        self.assertEqual(messages[2]["content"], "")
        tool_call = messages[2]["tool_calls"][0]
        self.assertEqual(len(tool_call["id"]), 9)
        self.assertTrue(tool_call["id"].isalnum())
        self.assertEqual(tool_call["function"], {"name": "search", "arguments": "{}"})

        # Check tool message tool_call_id normalized to match assistant tool_call id
        self.assertEqual(messages[3]["role"], "tool")
        self.assertEqual(messages[3]["tool_call_id"], tool_call["id"])

        # Check expected dropped items
        self.assertIn("message[system].extra_system_key", dropped)
        self.assertIn("message[user].extra_user_key", dropped)
        self.assertIn("content_part.extra_part_key", dropped)
        self.assertIn("message[assistant].extra_assistant_key", dropped)
        self.assertIn("tool_call.extra_tc_key", dropped)
        self.assertIn("tool_call.function.extra_func_key", dropped)
        self.assertIn("message[tool].extra_tool_msg_key", dropped)

    def test_cleaning_tools_and_default_parameters(self):
        body = {
            "model": "mistral-large-latest",
            "tools": [
                {
                    "type": "function",
                    "function": {
                        "name": "get_weather",
                        "description": "Obtiene clima",
                        "extra_param": "invalid",
                    },
                    "extra_tool_field": "invalid",
                }
            ],
        }
        body_original = copy.deepcopy(body)
        dropped = set()

        result = adapt_mistral(body, dropped)

        self.assertEqual(body, body_original)
        tools = result["tools"]
        self.assertEqual(len(tools), 1)
        self.assertEqual(
            tools[0],
            {
                "type": "function",
                "function": {
                    "name": "get_weather",
                    "description": "Obtiene clima",
                    "parameters": {"type": "object", "properties": {}},
                },
            },
        )
        self.assertIn("tool.extra_tool_field", dropped)
        self.assertIn("tool.function.extra_param", dropped)


class TestAdaptGroq(unittest.TestCase):
    def test_max_tokens_exceeding_limit_is_capped_and_dropped(self):
        body = {
            "model": "qwen-2.5-coder-32b",
            "max_tokens": 20000,
            "max_completion_tokens": 30000,
        }
        body_original = copy.deepcopy(body)
        dropped = set()

        result = adapt_groq(body, dropped)

        self.assertEqual(body, body_original)
        self.assertEqual(result["max_tokens"], GROQ_MAX_TOKENS)
        self.assertEqual(result["max_completion_tokens"], GROQ_MAX_TOKENS)
        self.assertIn(f"body.max_tokens>{GROQ_MAX_TOKENS}", dropped)
        self.assertIn(f"body.max_completion_tokens>{GROQ_MAX_TOKENS}", dropped)

    def test_max_tokens_within_limit_unchanged(self):
        body = {
            "model": "qwen-2.5-coder-32b",
            "max_tokens": 4096,
            "max_completion_tokens": GROQ_MAX_TOKENS,
        }
        body_original = copy.deepcopy(body)
        dropped = set()

        result = adapt_groq(body, dropped)

        self.assertEqual(body, body_original)
        self.assertEqual(result["max_tokens"], 4096)
        self.assertEqual(result["max_completion_tokens"], GROQ_MAX_TOKENS)
        self.assertEqual(dropped, set())


if __name__ == "__main__":
    unittest.main()

"""Tab state management for Refraction.

Provides the TabState dataclass for per-tab identity and form state.
The visual tab bar and tab manager are implemented in the SwiftUI frontend.
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass, field
from typing import Any


@dataclass
class TabState:
    """Per-tab state container.  One instance per open plot tab."""

    tab_id: str = ""
    chart_type: str = "bar"
    chart_type_idx: int = 0
    label: str = "Untitled"
    vars_snapshot: dict = field(default_factory=dict)
    file_path: str = ""
    sheet_name: str = ""
    validated: bool = False

    def __post_init__(self):
        if not self.tab_id:
            self.tab_id = uuid.uuid4().hex

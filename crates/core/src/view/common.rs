use std::sync::mpsc;
use chrono::Local;
use crate::device::CURRENT_DEVICE;
use crate::settings::{ButtonScheme, RotationLock};
use crate::framebuffer::UpdateMode;
use crate::geom::{Point, Rectangle};
use super::{View, RenderQueue, RenderData, ViewId, AppCmd, EntryId, EntryKind};
use super::menu::{Menu, MenuKind};
use super::notification::Notification;
use crate::context::Context;

pub fn shift(view: &mut dyn View, delta: Point) {
    *view.rect_mut() += delta;
    for child in view.children_mut().iter_mut() {
        shift(child.as_mut(), delta);
    }
}

pub fn locate<T: View>(view: &dyn View) -> Option<usize> {
    for (index, child) in view.children().iter().enumerate() {
        if child.as_ref().is::<T>() {
            return Some(index);
        }
    }
    None
}

pub fn rlocate<T: View>(view: &dyn View) -> Option<usize> {
    for (index, child) in view.children().iter().enumerate().rev() {
        if child.as_ref().is::<T>() {
            return Some(index);
        }
    }
    None
}

pub fn locate_by_id(view: &dyn View, id: ViewId) -> Option<usize> {
    view.children().iter().position(|c| c.view_id().map_or(false, |i| i == id))
}

pub fn overlapping_rectangle(view: &dyn View) -> Rectangle {
    let mut rect = *view.rect();
    for child in view.children() {
        rect.absorb(&overlapping_rectangle(child.as_ref()));
    }
    rect
}

// Transfer the notifications from the view1 to the view2.
pub fn transfer_notifications(view1: &mut dyn View, view2: &mut dyn View, rq: &mut RenderQueue, context: &mut Context) {
    for index in (0..view1.len()).rev() {
        if view1.child(index).is::<Notification>() {
            let mut child = view1.children_mut().remove(index);
            if view2.rect() != view1.rect() {
                let (tx, _rx) = mpsc::channel();
                child.resize(*view2.rect(), &tx, rq, context);
            }
            view2.children_mut().push(child);
        }
    }
}

pub fn toggle_main_menu(view: &mut dyn View, rect: Rectangle, enable: Option<bool>, rq: &mut RenderQueue, context: &mut Context) {
    if let Some(index) = locate_by_id(view, ViewId::MainMenu) {
        if let Some(true) = enable {
            return;
        }
        rq.add(RenderData::expose(*view.child(index).rect(), UpdateMode::Gui));
        view.children_mut().remove(index);
    } else {
        if let Some(false) = enable {
            return;
        }

        let apps = vec![EntryKind::Command("Calculator".to_string(),
                                           EntryId::Launch(AppCmd::Calculator)),
                        EntryKind::Command("Dictionary".to_string(),
                                           EntryId::Launch(AppCmd::Dictionary { query: "".to_string(), language: "".to_string() }))];
        let mut entries = vec![EntryKind::Command("System Info".to_string(),
                                                  EntryId::SystemInfo),
                               EntryKind::Separator,
                               EntryKind::CheckBox("Enable WiFi".to_string(),
                                                   EntryId::ToggleWifi,
                                                   context.settings.wifi),
                               EntryKind::Separator,
                               EntryKind::SubMenu("Applications".to_string(), apps),
                               EntryKind::Separator];

        entries.push(EntryKind::Command("Connect USB".to_string(), EntryId::ConnectUSB));
        entries.push(EntryKind::Command("Power Off".to_string(), EntryId::PowerOff));

        let main_menu = Menu::new(rect, ViewId::MainMenu, MenuKind::DropDown, entries, context);
        rq.add(RenderData::new(main_menu.id(), *main_menu.rect(), UpdateMode::Gui));
        view.children_mut().push(Box::new(main_menu) as Box<dyn View>);
    }
}

pub fn toggle_battery_menu(view: &mut dyn View, rect: Rectangle, enable: Option<bool>, rq: &mut RenderQueue, context: &mut Context) {
    if let Some(index) = locate_by_id(view, ViewId::BatteryMenu) {
        if let Some(true) = enable {
            return;
        }
        rq.add(RenderData::expose(*view.child(index).rect(), UpdateMode::Gui));
        view.children_mut().remove(index);
    } else {
        if let Some(false) = enable {
            return;
        }

        let mut entries = Vec::new();

        match context.battery.status().ok().zip(context.battery.capacity().ok()) {
            Some((status, capacity)) => {
                for (i, (s, c)) in status.iter().zip(capacity.iter()).enumerate() {
                    entries.push(EntryKind::Message(format!("{:?} {}%", s, c),
                                                    if i > 0 { Some("cover".to_string()) } else { None }));
                }
            },
            _ => {
                entries.push(EntryKind::Message("Information Unavailable".to_string(), None));
            },
        }

        let battery_menu = Menu::new(rect, ViewId::BatteryMenu, MenuKind::DropDown, entries, context);
        rq.add(RenderData::new(battery_menu.id(), *battery_menu.rect(), UpdateMode::Gui));
        view.children_mut().push(Box::new(battery_menu) as Box<dyn View>);
    }
}

pub fn toggle_clock_menu(view: &mut dyn View, rect: Rectangle, enable: Option<bool>, rq: &mut RenderQueue, context: &mut Context) {
    if let Some(index) = locate_by_id(view, ViewId::ClockMenu) {
        if let Some(true) = enable {
            return;
        }
        rq.add(RenderData::expose(*view.child(index).rect(), UpdateMode::Gui));
        view.children_mut().remove(index);
    } else {
        if let Some(false) = enable {
            return;
        }
        let now = Local::now();
        let current_hour_24 = now.format("%H").to_string().parse::<u32>().unwrap_or(0);
        let current_minute = now.format("%M").to_string().parse::<u32>().unwrap_or(0);
        let current_is_pm = current_hour_24 >= 12;
        let current_hour_12 = match current_hour_24 {
            0 => 12,
            13..=23 => current_hour_24 - 12,
            _ => current_hour_24,
        };

        let am_pm: Vec<EntryKind> = [(false, "AM"), (true, "PM")].iter().map(|(is_pm, label)| {
            EntryKind::RadioButton(label.to_string(),
                                   EntryId::SetClockAmPm(*is_pm),
                                   *is_pm == current_is_pm)
        }).collect();

        let hours: Vec<EntryKind> = (1..=12).map(|h| {
            EntryKind::RadioButton(format!("{}", h),
                                   EntryId::SetClockHour12(h),
                                   h == current_hour_12)
        }).collect();

        let minute_buckets: Vec<EntryKind> = (0..6).map(|bucket| {
            let start = bucket * 10;
            let end = start + 9;
            let inner: Vec<EntryKind> = (start..=end).map(|m| {
                EntryKind::RadioButton(format!("{:02}", m),
                                       EntryId::SetClockMinute(m),
                                       m == current_minute)
            }).collect();
            EntryKind::SubMenu(format!("{}-{}", start, end), inner)
        }).collect();

        let entries = vec![
            EntryKind::SubMenu("AM/PM".to_string(), am_pm),
            EntryKind::SubMenu("Set Hour".to_string(), hours),
            EntryKind::SubMenu("Set Minute".to_string(), minute_buckets),
        ];
        let clock_menu = Menu::new(rect, ViewId::ClockMenu, MenuKind::DropDown, entries, context);
        rq.add(RenderData::new(clock_menu.id(), *clock_menu.rect(), UpdateMode::Gui));
        view.children_mut().push(Box::new(clock_menu) as Box<dyn View>);
    }
}

pub fn toggle_input_history_menu(view: &mut dyn View, id: ViewId, rect: Rectangle, enable: Option<bool>, rq: &mut RenderQueue, context: &mut Context) {
    if let Some(index) = locate_by_id(view, ViewId::InputHistoryMenu) {
        if let Some(true) = enable {
            return;
        }
        rq.add(RenderData::expose(*view.child(index).rect(), UpdateMode::Gui));
        view.children_mut().remove(index);
    } else {
        if let Some(false) = enable {
            return;
        }
        let entries = context.input_history.get(&id)
                             .map(|h| h.iter().map(|s|
                                 EntryKind::Command(s.to_string(),
                                                    EntryId::SetInputText(id, s.to_string())))
                                           .collect::<Vec<EntryKind>>());
        if let Some(entries) = entries {
            let menu_kind = match id {
                ViewId::HomeSearchInput |
                ViewId::ReaderSearchInput |
                ViewId::DictionarySearchInput |
                ViewId::CalculatorInput => MenuKind::DropDown,
                _ => MenuKind::Contextual,
            };
            let input_history_menu = Menu::new(rect, ViewId::InputHistoryMenu, menu_kind, entries, context);
            rq.add(RenderData::new(input_history_menu.id(), *input_history_menu.rect(), UpdateMode::Gui));
            view.children_mut().push(Box::new(input_history_menu) as Box<dyn View>);
        }
    }
}

pub fn toggle_keyboard_layout_menu(view: &mut dyn View, rect: Rectangle, enable: Option<bool>, rq: &mut RenderQueue, context: &mut Context) {
    if let Some(index) = locate_by_id(view, ViewId::KeyboardLayoutMenu) {
        if let Some(true) = enable {
            return;
        }
        rq.add(RenderData::expose(*view.child(index).rect(), UpdateMode::Gui));
        view.children_mut().remove(index);
    } else {
        if let Some(false) = enable {
            return;
        }
        let entries = context.keyboard_layouts.keys()
                             .map(|s| EntryKind::Command(s.to_string(),
                                                         EntryId::SetKeyboardLayout(s.to_string())))
                             .collect::<Vec<EntryKind>>();
        let keyboard_layout_menu = Menu::new(rect, ViewId::KeyboardLayoutMenu, MenuKind::Contextual, entries, context);
        rq.add(RenderData::new(keyboard_layout_menu.id(), *keyboard_layout_menu.rect(), UpdateMode::Gui));
        view.children_mut().push(Box::new(keyboard_layout_menu) as Box<dyn View>);
    }
}

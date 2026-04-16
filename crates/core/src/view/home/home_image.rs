use std::path::PathBuf;
use crate::device::CURRENT_DEVICE;
use crate::document::{Location, open};
use crate::geom::Rectangle;
use crate::font::Fonts;
use crate::color::WHITE;
use super::{View, Event, Hub, Bus, Id, ID_FEEDER, RenderQueue};
use crate::framebuffer::Framebuffer;
use crate::context::Context;

pub struct HomeImage {
    id: Id,
    rect: Rectangle,
    children: Vec<Box<dyn View>>,
    path: PathBuf,
}

impl HomeImage {
    pub fn new(rect: Rectangle, path: PathBuf) -> HomeImage {
        HomeImage {
            id: ID_FEEDER.next(),
            rect,
            children: Vec::new(),
            path,
        }
    }
}

impl View for HomeImage {
    fn handle_event(&mut self, _evt: &Event, _hub: &Hub, _bus: &mut Bus, _rq: &mut RenderQueue, _context: &mut Context) -> bool {
        false
    }

    fn render(&self, fb: &mut dyn Framebuffer, _rect: Rectangle, _fonts: &mut Fonts) {
        fb.draw_rectangle(&self.rect, WHITE);

        if let Some(mut doc) = open(&self.path) {
            if let Some((width, height)) = doc.dims(0) {
                let w_ratio = self.rect.width() as f32 / width;
                let h_ratio = self.rect.height() as f32 / height;
                let scale = w_ratio.max(h_ratio);
                if let Some((pixmap, _)) = doc.pixmap(Location::Exact(0),
                                                      scale,
                                                      CURRENT_DEVICE.color_samples()) {
                    let dx = (self.rect.width() as i32 - pixmap.width as i32) / 2;
                    let dy = (self.rect.height() as i32 - pixmap.height as i32) / 2;
                    let pt = self.rect.min + pt!(dx, dy);
                    fb.draw_pixmap(&pixmap, pt);
                }
            }
        }
    }

    fn rect(&self) -> &Rectangle {
        &self.rect
    }

    fn rect_mut(&mut self) -> &mut Rectangle {
        &mut self.rect
    }

    fn children(&self) -> &Vec<Box<dyn View>> {
        &self.children
    }

    fn children_mut(&mut self) -> &mut Vec<Box<dyn View>> {
        &mut self.children
    }

    fn id(&self) -> Id {
        self.id
    }
}

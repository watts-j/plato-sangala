use crate::device::CURRENT_DEVICE;
use crate::framebuffer::Framebuffer;
use crate::geom::{Rectangle, CornerSpec, BorderSpec};
use crate::font::{Fonts, font_from_style, NORMAL_STYLE};
use super::{View, Event, Hub, Bus, Id, ID_FEEDER, RenderQueue, ViewId, SliderId, Align};
use super::{SMALL_BAR_HEIGHT, THICKNESS_LARGE, BORDER_RADIUS_MEDIUM};
use super::label::Label;
use super::slider::Slider;
use super::icon::Icon;
use crate::gesture::GestureEvent;
use crate::color::{BLACK, WHITE};
use crate::unit::scale_by_dpi;
use crate::context::Context;

pub struct FrontlightWindow {
    id: Id,
    rect: Rectangle,
    children: Vec<Box<dyn View>>,
}

impl FrontlightWindow {
    pub fn new(context: &mut Context) -> FrontlightWindow {
        let id = ID_FEEDER.next();
        let fonts = &mut context.fonts;
        let levels = context.frontlight.levels();
        let mut children = Vec::new();
        let dpi = CURRENT_DEVICE.dpi;
        let (width, height) = context.display.dims;
        let small_height = scale_by_dpi(SMALL_BAR_HEIGHT, dpi) as i32;
        let thickness = scale_by_dpi(THICKNESS_LARGE, dpi) as i32;
        let border_radius = scale_by_dpi(BORDER_RADIUS_MEDIUM, dpi) as i32;

        let padding = {
            let font = font_from_style(fonts, &NORMAL_STYLE, dpi);
            font.em() as i32
        };

        let window_width = width as i32 - 2 * padding;

        let mut window_height = small_height * 2 + 2 * padding;

        if CURRENT_DEVICE.has_natural_light() {
            window_height += small_height;
        }

        let dx = (width as i32 - window_width) / 2;
        let dy = (height as i32 - window_height) / 3;

        let rect = rect![dx, dy, dx + window_width, dy + window_height];

        let corners = CornerSpec::Detailed {
            north_west: 0,
            north_east: border_radius - thickness,
            south_east: 0,
            south_west: 0,
        };

        let close_icon = Icon::new("close",
                                   rect![rect.max.x - small_height,
                                         rect.min.y + thickness,
                                         rect.max.x - thickness,
                                         rect.min.y + small_height],
                                   Event::Close(ViewId::Frontlight))
                              .corners(Some(corners));

        children.push(Box::new(close_icon) as Box<dyn View>);

        let label = Label::new(rect![rect.min.x + small_height,
                                     rect.min.y + thickness,
                                     rect.max.x - small_height,
                                     rect.min.y + small_height],
                               "Frontlight".to_string(),
                               Align::Center);

        children.push(Box::new(label) as Box<dyn View>);

        if CURRENT_DEVICE.has_natural_light() {
            let max_label_width = {
                let font = font_from_style(fonts, &NORMAL_STYLE, dpi);
                ["Intensity", "Warmth"].iter().map(|t| font.plan(t, None, None).width)
                                                           .max().unwrap() as i32
            };

            for (index, slider_id) in [SliderId::LightIntensity, SliderId::LightWarmth].iter().enumerate() {
                let min_y = rect.min.y + (index + 1) as i32 * small_height;
                let label = Label::new(rect![rect.min.x + padding,
                                             min_y,
                                             rect.min.x + 2 * padding + max_label_width,
                                             min_y + small_height],
                                       slider_id.label(),
                                       Align::Right(padding / 2));
                children.push(Box::new(label) as Box<dyn View>);

                let value = if *slider_id == SliderId::LightIntensity {
                    levels.intensity
                } else {
                    levels.warmth
                };

                let slider = Slider::new(rect![rect.min.x + max_label_width + 3 * padding,
                                               min_y,
                                               rect.max.x - padding,
                                               min_y + small_height],
                                         *slider_id,
                                         value,
                                         0.0,
                                         100.0);
                children.push(Box::new(slider) as Box<dyn View>);
            }
        } else {
            let min_y = rect.min.y + small_height;
            let slider = Slider::new(rect![rect.min.x + padding,
                                           min_y,
                                           rect.max.x - padding,
                                           min_y + small_height],
                                     SliderId::LightIntensity,
                                     levels.intensity,
                                     0.0,
                                     100.0);
            children.push(Box::new(slider) as Box<dyn View>);
        }

        FrontlightWindow {
            id,
            rect,
            children,
        }
    }
}

impl View for FrontlightWindow {
    fn handle_event(&mut self, evt: &Event, hub: &Hub, _bus: &mut Bus, _rq: &mut RenderQueue, context: &mut Context) -> bool {
        match *evt {
            Event::Slider(SliderId::LightIntensity, value, _) => {
                context.frontlight.set_intensity(value);
                true
            },
            Event::Slider(SliderId::LightWarmth, value, _) => {
                context.frontlight.set_warmth(value);
                true
            },
            Event::Gesture(GestureEvent::Tap(center)) if !self.rect.includes(center) => {
                hub.send(Event::Close(ViewId::Frontlight)).ok();
                true
            },
            Event::Gesture(..) => true,
            _ => false,
        }
    }

    fn render(&self, fb: &mut dyn Framebuffer, _rect: Rectangle, _fonts: &mut Fonts) {
        let dpi = CURRENT_DEVICE.dpi;

        let border_radius = scale_by_dpi(BORDER_RADIUS_MEDIUM, dpi) as i32;
        let border_thickness = scale_by_dpi(THICKNESS_LARGE, dpi) as u16;

        fb.draw_rounded_rectangle_with_border(&self.rect,
                                              &CornerSpec::Uniform(border_radius),
                                              &BorderSpec { thickness: border_thickness,
                                                            color: BLACK },
                                              &WHITE);
    }

    fn resize(&mut self, _rect: Rectangle, hub: &Hub, rq: &mut RenderQueue, context: &mut Context) {
        let dpi = CURRENT_DEVICE.dpi;
        let (width, height) = context.display.dims;
        let small_height = scale_by_dpi(SMALL_BAR_HEIGHT, dpi) as i32;
        let thickness = scale_by_dpi(THICKNESS_LARGE, dpi) as i32;

        let padding = {
            let font = font_from_style(&mut context.fonts, &NORMAL_STYLE, dpi);
            font.em() as i32
        };

        let window_width = width as i32 - 2 * padding;

        let mut window_height = small_height * 2 + 2 * padding;

        if CURRENT_DEVICE.has_natural_light() {
            window_height += small_height;
        }

        let dx = (width as i32 - window_width) / 2;
        let dy = (height as i32 - window_height) / 3;

        let rect = rect![dx, dy, dx + window_width, dy + window_height];

        self.children[0].resize(rect![rect.max.x - small_height,
                                      rect.min.y + thickness,
                                      rect.max.x - thickness,
                                      rect.min.y + small_height],
                                hub, rq, context);
        self.children[1].resize(rect![rect.min.x + small_height,
                                      rect.min.y + thickness,
                                      rect.max.x - small_height,
                                      rect.min.y + small_height],
                                hub, rq, context);

        if CURRENT_DEVICE.has_natural_light() {
            let max_label_width = {
                let font = font_from_style(&mut context.fonts, &NORMAL_STYLE, dpi);
                ["Intensity", "Warmth"].iter().map(|t| font.plan(t, None, None).width)
                                                           .max().unwrap() as i32
            };
            let mut index = 2;
            for i in 0..2usize {
                let min_y = rect.min.y + (i + 1) as i32 * small_height;
                self.children[index].resize(rect![rect.min.x + padding,
                                                  min_y,
                                                  rect.min.x + 2 * padding + max_label_width,
                                                  min_y + small_height],
                                            hub, rq, context);
                self.children[index+1].resize(rect![rect.min.x + max_label_width + 3 * padding,
                                                    min_y,
                                                    rect.max.x - padding,
                                                    min_y + small_height],
                                              hub, rq, context);
                index += 2;
            }
        } else {
            let min_y = rect.min.y + small_height;
            self.children[2].resize(rect![rect.min.x + padding,
                                          min_y,
                                          rect.max.x - padding,
                                          min_y + small_height],
                                    hub, rq, context);
        }

        self.rect = rect;
    }

    fn is_background(&self) -> bool {
        true
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

#!/usr/bin/env ruby
#encoding=utf-8
require 'nokogiri'
require 'yaml'
R = 5.556
W = 2500
H = 1251
dLng = -180
dLat = -90
lLng = 360
lLat = 180

loc_list = [
  :cn, 
  :us,
  :eu,
].map do |na|
  svg_fp = "cities_#{na}.svg"
  doc = Nokogiri::XML.parse File.read svg_fp
  pos_list = doc.css('ellipse, path').map do |el|
    if el.name == 'path'
      points = el[:d].scan(/m ([\d.]+),([\d.]+)/)
      x, y = points.reduce([0, 0]) do |p1, p2|
        [p1.first + p2.first.to_f, p1.last + p2.last.to_f]
      end
      x /= points.length
      y /= points.length
    else
      x = el[:cx]
      y = el[:cy]
    end
    {x: x.to_f, y: y.to_f, labels: []}
  end
  doc.css('text').each do |label|
    tspan_list = label.css('tspan')
    if tspan_list.empty?
      text = [label.text.strip]
    else
      text = tspan_list.map(&:text).map(&:strip)
    end
    x = label[:x].to_f
    y = label[:y].to_f
    # if /^[a-zA-Z ]+$/ === text
    #   y -= 2*R
    # end
    pos = pos_list.min_by do |pos|
      (pos[:x] + R - x) ** 2 + (pos[:y] - R - y) ** 2
    end
    pos[:labels].push text
  end
  pos_list.map do |pos|
    lng = pos[:x] / W * lLng + dLng
    lat = pos[:y] / H * lLat + dLat
    {
      'name' => pos[:labels].join("<br/>"),
      'pos' => {
        'lng' => lng,
        'lat' => lat
      },
      'template' => "#{na}_city"
    }
  end
end.flatten

File.write '../index.yaml', loc_list.to_yaml
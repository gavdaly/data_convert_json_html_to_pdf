#!/usr/bin/env ruby

require 'fileutils'
require 'pdfkit'
require 'json'
require 'nokogiri'

PDFKit.configure do |config|
  config.default_options = {
    :page_size => 'Letter',
    :print_media_type => true
  }
  config.root_url = "http://localhost"
  config.verbose = true
end

def open_file_and_parse(f_name)
  file_to_be_parsed = clinical_documents = File.read(f_name)
  JSON.parse(file_to_be_parsed)['RECORDS']
end

@docs = open_file_and_parse 'ClinicalSession.json'
@link = open_file_and_parse 'ClinicalSessionLink.json'
@data = open_file_and_parse 'ClinicalSessionData.json'
@patients = open_file_and_parse 'pat.json'


def save_html_to_file(html, name)
  generated_pdf = PDFKit.new(html, :page_size => 'Letter')
  generated_pdf.to_file("pdf/#{name}.pdf")
end

def file_name(record, name)
  id = record['Session_Id']
  date = record['Session_Date']
  name + ' - ' + id + ' - ' + date[0...10] + '.pdf'
end


def get_patient_name(id)
  name = ""
  @patients.each do |patient|
    if patient['pid'] == id
      name = patient['pfname'].rstrip + ' ' + patient['plname'].rstrip
      break
    end
  end
  name
end

def get_data_for_session(id)
  session_data = []
  @data.each do |data|
    if data['Session_Id'] == id
      session_data << data
    end
  end
  session_data
end

def get_record_for_session id
  record = ""
  @docs.each do |doc|
    if doc['Session_Id'] == id
      record = doc
      break
    end
  end
  record
end

def input_values_into_form form_data, form
  page = Nokogiri::HTML(form)
  inputs = page.css("input")
  form_data.each do |data|
    inputs.each do |input|
      if input['name'] == data['label']
        input['value'] = data['value']
        break
      end
    end
  end
  page
end


@link.each do |link|
  d = get_data_for_session link['Session_ID']
  record = get_record_for_session link['Session_ID']
  f_name = file_name record, get_patient_name(link['Patient_ID'])
  form = input_values_into_form d, record['Form']
  save_html_to_file form.to_s, f_name
end

puts "\n\nDONE!! DONE!! DONE!!"

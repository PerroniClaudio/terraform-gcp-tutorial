# Bucket 

resource "google_storage_bucket" "website" {
    name = "281120240909-website-bucket"
    location = "EU"
}

# Access control - make it public 

resource "google_storage_object_access_control" "public_rule" {
  object = google_storage_bucket_object.static_site_source.name
  bucket = google_storage_bucket.website.name
  role = "READER"
  entity = "allUsers"
}

# upload index.html to the bucket

resource "google_storage_bucket_object" "static_site_source" {
    name = "index.html"
    source = "../website/index.html"
    bucket = google_storage_bucket.website.name
}

# Reserving a static external IP address

resource "google_compute_global_address" "static_website_ip" {
    name = "static-website-lb-ip"
} 

# Get the managed DNS zone 

data "google_dns_managed_zone" "dns_zone" {
  name = "terraform-gcp"
}

# Add the ip to the DNS zone

resource "google_dns_record_set" "website" {
    name = "website.${data.google_dns_managed_zone.dns_zone.dns_name}"
    type = "A"
    ttl = 300
    managed_zone = data.google_dns_managed_zone.dns_zone.name
    rrdatas = [google_compute_global_address.static_website_ip.address]
}

# Add the bucket as a CDN backend

resource "google_compute_backend_bucket" "website-backend" {
    name = "website-backend-bucket"
    bucket_name = google_storage_bucket.website.name
    description = "Contiene i file per il sito"
    enable_cdn = true
}

# GCP URL MAP

resource "google_compute_url_map" "website-map" {
    name = "website-url-map"
    default_service = google_compute_backend_bucket.website-backend.self_link
    host_rule {
      hosts = ["*"]
      path_matcher = "allpaths"
    }
    path_matcher {
        name = "allpaths"
        default_service = google_compute_backend_bucket.website-backend.self_link
        
    }
}

# Load balancer http proxy 

resource "google_compute_target_http_proxy" "website-proxy" {
    name = "website-proxy"
    url_map = google_compute_url_map.website-map.self_link
}

# Forwarding rule

resource "google_compute_global_forwarding_rule" "default" {
    name = "website-forwarding-rule"
    load_balancing_scheme = "EXTERNAL"
    ip_address = google_compute_global_address.static_website_ip.address
    ip_protocol = "TCP"
    port_range = "80"
    target = google_compute_target_http_proxy.website-proxy.self_link
}

# Create SSL certificate (takes a while)

resource "google_compute_managed_ssl_certificate" "website-ssl" {
    name = "website-ssl"
    managed {
        domains = [google_dns_record_set.website.name]
    }
}